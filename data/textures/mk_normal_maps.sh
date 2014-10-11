#!/bin/bash
set -eu

gimp -i -b '(load "process_textures.scm") (kam-batch-normal-maps)' -b '(gimp-quit 0)'
