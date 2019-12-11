#!/usr/bin/python3

import argparse
import hashlib
import logging
import os
import os.path
import subprocess
import tempfile
from xml.etree import ElementTree

_NS = {
    'cim': 'http://schemas.dmtf.org/wbem/wscim/1/common',
    'ovf': 'http://schemas.dmtf.org/ovf/envelope/1',
    'rasd':
    'http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData',
    'vmw': 'http://www.vmware.com/schema/ovf',
    'vssd':
    'http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_VirtualSystemSettingData',
    'xsi': 'http://www.w3.org/2001/XMLSchema-instance',
}


def _parse_size(ssize: str) -> int:
    ssize = ssize.upper()
    if ssize.endswith('K'):
        return int(ssize[:-1]) * 1024
    if ssize.endswith('M'):
        return int(ssize[:-1]) * 1024**2
    if ssize.endswith('G'):
        return int(ssize[:-1]) * 1024**3
    return int(ssize)


def _attrib_name(name: str, ns: str = 'ovf') -> str:
    return f'{{{_NS[ns]}}}{name}'


def _attrib(el: ElementTree.Element, name: str, ns: str = 'ovf') -> str:
    return el.attrib[_attrib_name(name, ns)]


def _resize(box_path: str, disk_size: int) -> None:
    ovf = ElementTree.parse(os.path.join(box_path, 'box.ovf'))

    disk = ovf.find('./ovf:DiskSection/ovf:Disk[1]', namespaces=_NS)
    disk_capacity = int(_attrib(disk, 'capacity'))
    if disk_capacity >= disk_size:
        return

    file_reference = ovf.find(
        f"./ovf:References/ovf:File[@ovf:id='{_attrib(disk, 'fileRef')}']",
        namespaces=_NS)
    file_path = os.path.join(box_path, _attrib(file_reference, 'href'))
    logging.info('Resizing %s...', file_path)
    with tempfile.TemporaryDirectory(dir=box_path) as tmpdir:
        vdi_file_path = os.path.join(tmpdir, 'disk.vdi')
        vmdk_file_path = os.path.join(tmpdir, 'disk.vmdk')

        subprocess.check_call([
            '/usr/bin/VBoxManage',
            'clonehd',
            file_path,
            vdi_file_path,
            '--format',
            'vdi',
        ])
        subprocess.check_call([
            '/usr/bin/VBoxManage',
            'modifyhd',
            vdi_file_path,
            '--resizebyte',
            str(disk_size),
        ])
        subprocess.check_call([
            '/usr/bin/VBoxManage',
            'modifyhd',
            vdi_file_path,
            '--compact',
        ])
        subprocess.check_call([
            '/usr/bin/VBoxManage',
            'clonehd',
            vdi_file_path,
            vmdk_file_path,
            '--format',
            'vmdk',
        ])
        subprocess.check_call([
            '/usr/bin/VBoxManage',
            'closemedium',
            vdi_file_path,
            '--delete',
        ])
        subprocess.check_call([
            '/usr/bin/VBoxManage',
            'closemedium',
            vmdk_file_path,
        ])
        subprocess.check_call([
            '/usr/bin/VBoxManage',
            'closemedium',
            file_path,
        ])
        os.replace(vmdk_file_path, file_path)
    file_reference.attrib[_attrib_name('size')] = str(
        os.stat(file_path).st_size)
    disk.attrib[_attrib_name('capacity')] = str(disk_size)

    ovf.write(os.path.join(box_path, 'box.ovf'),
              xml_declaration=True,
              encoding='UTF-8',
              default_namespace='http://schemas.dmtf.org/ovf/envelope/1')


def _update_manifest(box_path: str) -> None:
    box_files = sorted(os.listdir(box_path))
    hashed_files = [p for p in box_files if p.endswith('.vmdk') or p.endswith('.ovf')]
    mf_path = [p for p in box_files if p.endswith('.mf')][0]
    logging.info('Updating manifest %s...', mf_path)
    with open(os.path.join(box_path, mf_path), 'w') as mf_file:
        for hashed_file in hashed_files:
            logging.info('Hashing %s...', hashed_file)
            h = hashlib.sha256()
            with open(os.path.join(box_path, hashed_file), 'rb') as f:
                while True:
                    buf = f.read(4096)
                    if not buf:
                        break
                    h.update(buf)
            mf_file.write(f'SHA256({hashed_file})= {h.hexdigest()}\n')


def _main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--verbose', action='store_true')
    parser.add_argument('--size', default='60G', type=_parse_size)
    parser.add_argument('box')
    args = parser.parse_args()

    if args.verbose:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.INFO)

    for prefix, uri in _NS.items():
        ElementTree.register_namespace(prefix, uri)
    _resize(args.box, args.size)
    _update_manifest(args.box)


if __name__ == '__main__':
    _main()
