#!/usr/bin/python3

import argparse
import subprocess
import json


def _get_next_version() -> str:
    previous_version_str = json.loads(
        subprocess.check_output([
            '/usr/bin/vagrant',
            'cloud',
            'search',
            'omegaup/dev',
            '--json',
            '--sort-by=created',
            '--limit=1',
        ],
                                universal_newlines=True))[0]['version']
    previous_version = [int(x) for x in previous_version_str.split('.')]
    previous_version[-1] += 1
    return '.'.join(str(x) for x in previous_version)


def _main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--description', type=str, required=True)
    parser.add_argument('--boxfile',
                        type=str,
                        default='packer_virtualbox-ovf_virtualbox.box')
    parser.add_argument('--version', type=str)
    args = parser.parse_args()

    if args.version:
        version = args.version
    else:
        version = _get_next_version()

    subprocess.check_call([
        '/usr/bin/vagrant',
        'cloud',
        'publish',
        'omegaup/dev',
        version,
        '--release',
        '--version-description',
        args.description,
        'virtualbox',
        args.boxfile,
    ])


if __name__ == '__main__':
    _main()
