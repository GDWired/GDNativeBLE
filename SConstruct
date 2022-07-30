#!/usr/bin/env python

import os
import sys
import subprocess

def add_sources(sources, dir, extension):
    for f in os.listdir(dir):
        if f.endswith('.' + extension):
            sources.append(dir + '/' + f)

if sys.version_info < (3,):
    def decode_utf8(x):
        return x
else:
    import codecs
    def decode_utf8(x):
        return codecs.utf_8_decode(x)[0]

def sys_exec(args):
    proc = subprocess.Popen(args, stdout=subprocess.PIPE, text=True)
    (out, err) = proc.communicate()
    return out.rstrip("\r\n").lstrip()

#################
#OPTIONS#########
#################

# Try to detect the host platform automatically.
# This is used if no `platform` argument is passed
if sys.platform == 'darwin':
    host_platform = 'osx'
else:
    raise ValueError(
        'Could not detect platform automatically, please specify with '
        'platform=<platform>'
    )

opts = Variables([], ARGUMENTS)
opts.Add(EnumVariable(
    'platform',
    'Target platform',
    host_platform,
    allowed_values=('osx'),
    ignorecase=2
))
opts.Add(EnumVariable(
    'bits',
    'Target platform bits',
    'default',
    ('default', '64')
))
# Must be the same setting as used for cpp_bindings
opts.Add(EnumVariable(
    'target',
    'Compilation target',
    'debug',
    allowed_values=('debug', 'release'),
    ignorecase=2
))
opts.Add(PathVariable(
    'cpp_bindings_dir',
    'Path to the cpp binding library',
    "../godot-cpp/",
    PathVariable.PathIsDir
))
opts.Add(PathVariable(
    'headers_dir',
    'Path to the directory containing Godot headers',
    'default',
    PathVariable.PathAccept
))
opts.Add(
    'ble_lib_dir',
    'Path to the BLE library',
    "libs/ble/"
)
opts.Add(EnumVariable(
    'macos_arch',
    'Target macOS architecture',
    'universal',
    ['universal', 'x86_64', 'arm64']
))

env = Environment(ENV = os.environ)
opts.Update(env)
Help(opts.GenerateHelpText(env))

is64 = sys.maxsize > 2**32
if (
    env['TARGET_ARCH'] == 'amd64' or
    env['TARGET_ARCH'] == 'x86_64'
):
    is64 = True

if env["headers_dir"] == 'default':
    env["headers_dir"] = os.environ.get("GODOT_HEADERS", env["cpp_bindings_dir"] + "godot-headers/")

if env['bits'] == 'default':
    env['bits'] = '64' if is64 else '32'

arch_suffix = env['bits']

###################
####FLAGS##########
###################
if env['platform'] == 'osx':
    # Use Clang on macOS by default
    env['CXX'] = 'clang++'

    if env['bits'] == '32':
        raise ValueError(
            'Only 64-bit builds are supported for the macOS target.'
        )

    if env["macos_arch"] == "universal":
        env.Append(LINKFLAGS=["-arch", "x86_64", "-arch", "arm64"])
        env.Append(CCFLAGS=["-arch", "x86_64", "-arch", "arm64"])
    else:
        env.Append(LINKFLAGS=["-arch", env["macos_arch"]])
        env.Append(CCFLAGS=["-arch", env["macos_arch"]])

    env.Append(CCFLAGS=['-std=c++14'])

    env.Append(LINKFLAGS=[
        '-framework',
        'Cocoa',
        '-Wl,-undefined,dynamic_lookup',
    ])

    if env['target'] == 'debug':
        env.Append(CCFLAGS=['-Og', '-g'])
    elif env['target'] == 'release':
        env.Append(CCFLAGS=['-O3'])

#####################
#ADD SOURCES#########
#####################
cpp_bindings_libname = 'libgodot-cpp.{}.{}.{}'.format(
                        env['platform'],
                        env['target'],
                        arch_suffix)

lfix = ""
if env["target"] == "debug":
    lfix = "L"
platform = env['platform']
if platform == "osx":
    libnativeble = 'libnativeble.dylib'
    cpp_bindings_libname += '.a'
    env.Append(CPPPATH=[env['headers_dir'], env['cpp_bindings_dir'] + 'include/', env['cpp_bindings_dir'] + 'include/core/',
               env['cpp_bindings_dir'] + 'include/gen/', env['ble_lib_dir'] + 'inc/'])
    env.Append(LIBS=[cpp_bindings_libname, libnativeble])
    env.Append(LIBPATH=[ env['cpp_bindings_dir'] + 'bin/', env['ble_lib_dir'] + 'osx/'])

sources = []
add_sources(sources, "./src", 'cpp')

###############
#BUILD LIB#####
###############

# determine to link as shared or static library

lib_name_without_bin = 'libgodotnativeble.{}.{}.{}'.format(
    env['platform'],
    env['target'],
    arch_suffix)

lib_name = 'bin/' + lib_name_without_bin

if platform == "osx":
    lib_path = lib_name + '.dylib'
    lib_name_dylib = lib_name_without_bin + '.dylib'
    def change_id(self, arg, env, executor = None):
        sys_exec(["install_name_tool", "-id", "@rpath/%s" % lib_name_dylib , lib_path])
        sys_exec(["install_name_tool", "-change", "@rpath/libnativeble.dylib", "@loader_path/libnativeble.dylib", lib_path])
        sys_exec(["cp", "bin/libgodotnativeble.osx.debug.64.dylib", "demo/bin/osx/"])
    library = env.SharedLibrary(target=lib_path, source=sources)
    change_id_action = Action('', change_id)

    AddPostAction(library, change_id_action)
Default(library)