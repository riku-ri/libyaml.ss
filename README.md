# libyaml.ss

## Usage

Refer to [docs/usage.md](docs/usage.md)

## Installation

This is a chicken scheme egg,
installation need to run by chichen scheme tools.

Another module `varg` is required,
install it before the later steps:
- https://github.com/riku-ri/varg.ss

To install locally, clone this git repository and update submodules :
```
git submodule update --remote --init --recursive
```

and then run the install command in the root path :
```
chicken-install -s -test -l .
```

## Development

Refer to [docs/dev.md](docs/dev.md)
