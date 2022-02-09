![fx](banner.png)

![Workflow status](https://github.com/jathu/fx/actions/workflows/ci.yml/badge.svg) ![Release status](https://github.com/jathu/fx/actions/workflows/release.yml/badge.svg)

fx is a workspace tool manager. It allows you to create consistent, discoverable, language-neutral and developer friendly command line tools. 

fx is still in beta and is subject to breaking changes until the [descriptor](src/protobuf/fx/descriptor) is bumped to v1 (currently v1beta).

<!--ts-->
   * [Installation](#installation)
      * [macOS](#macos)
      * [Linux](#linux)
   * [What is it?](#what-is-it)
      * [Step-by-Step Example](#step-by-step-example)
      * [Use Cases](#use-cases)
   * [Configuration](#configuration)
      * [Workspace Descriptor](#workspace-descriptor)
         * [FxWorkspaceDescriptor](#fxworkspacedescriptor)
      * [Command Descriptor](#command-descriptor)
         * [FxCommandDescriptor](#fxcommanddescriptor)
         * [OptionDescriptor](#optiondescriptor)
         * [ArgumentDescriptor](#argumentdescriptor)
         * [RuntimeDescriptor](#runtimedescriptor)
         * [BoolValueDescriptor](#boolvaluedescriptor)
         * [IntValueDescriptor](#intvaluedescriptor)
         * [DoubleValueDescriptor](#doublevaluedescriptor)
         * [StringValueDescriptor](#stringvaluedescriptor)
   * [Runtime](#runtime)
   * [FAQs](#faqs)
   * [Development](#development)
      * [Setup](#setup)
      * [Frequently Used Commands](#frequently-used-commands)
      * [Third Party Libraries](#third-party-libraries)

<!-- Updated: Tue Feb  8 18:27:14 PST 2022 -->

<!--te-->

## Installation

### macOS

```shell
$ brew tap jathu/fx https://github.com/jathu/fx
$ brew install jathu/fx/fx
```

### Linux

Checkout the releases https://github.com/jathu/fx/releases. A better solution, preferably using a package manager is coming soon. Contributions are welcome!

## What is it?

fx is a command line tool (CLI) that hosts and manages other CLIs. It takes care of the tedious parts of CLIs like argument parsing, validation, help/man pages and updates. fx has dynamic subcommands based on it's current directory — these subcommands are created by you, the user. Still don't understand? Walk through the step-by-step tutorial below.

### Step-by-Step Example

Suppose we have a large repository and we want to create a code formatter for the various languages in the repository. Why would we want to do this? Code formatters vary from language to language, so remembering all of them is a lot harder than just `fx format`.

First, we will need to make our repository a fx workspace be creating a `workspace descriptor` in the root of our repository:

```yaml
# File: ~/acme-corp/workspace.fx.yaml

# The version of the fx workspace descriptor this conforms to
descriptor_version: v1beta
```

This is now the root of our workspace. To create a `fx format` command, we need to create a `command descriptor`:

```yaml
# File: ~/acme-corp/format/command.fx.yaml

# The version of the fx command descriptor this conforms to
descriptor_version: v1beta
# The short description about what this tool does
synopsis: Format and analyze code.
# The long, more detailed description about what this tool does
description: Format and run code analysis on all changed files from the previous format run.
# The available options for this command
options:
  - name: test
    short_name: t
    # The description about what this option is for and does
    description: Run formatting tests without overwriting.
    # This option will be a bool value. --test is either present or not
    bool_value: {}
  - name: language
    short_name: l
    description: Only format specific languages.
    # This option will be a list of strings. The values are also limited by choice
    string_value:
      list: true
      choices:
        - all
        - cpp
        - c++
        - bazel
        - java
        - python
      default: all
runtime:
  # Tell fx how to invoke the underlying script. Here we chose to write our
  # script in python, but this can anything
  run: python3 $FX_WORKSPACE_DIRECTORY/format/main.py
```

Note that the command name is implicit in the path of the command descriptor with respect to the workspace descriptor. Also note that we've defined our run command as a Python script. We can now define our script:

```python
# File: ~/acme-corp/format/main.py

import sys
import json

# fx will parse the user arguments conforming to the command descriptor and pass
# the results to the underlying command as a well defined JSON blob.
args = json.loads(sys.argv[1])

# All options are guaranteed to exist
languages = args["language"]["value"]
should_format_all = "all" in languages
is_test_mode = args["test"]["value"]

# Do the actual formatting here...
```

With this, the tool is now available to everyone in the repository and easily discoverable.

```
$ fx

fx — workspace tool manager [version 0.1]

Usage:  fx <command> --help
        fx <command> <options...> <args...>

[workspace fx]
    list - List available commands.
    help - Learn more about fx.
    version - Print the fx version.

[workspace ~/acme-corp/workspace.fx.yaml]
    format - Format and analyze code.
    server/start - Start the backend server.
    frontend/start - Start the frontend React server.
    frontend/gql/gen - Generate the GraphQL bindings.
```

fx automatically provides a consistent well formatted help menu for all commands.

```
$ fx format --help

fx format — Format and analyze code.

   usage:
      fx format [-t|--test] [-l|--language=<language...>]

Format and run code analysis on all changed files from the previous format run.

· OPTIONS ······································································

   --test, -t · bool · optional
      Run formatting tests without overwriting.
      Default: false

   --language, -l · List<string> · optional
      Only format specific languages.
      Default: all | Choices: all, cpp, c++, bazel, java, python
```

The command can be invoked like any other CLI tool.

```
$ fx format -l bazel -l c++

Formatting Bazel files...
Formatting C++ files...  
```

### Use Cases

* Quickly spin up CLI tools without setting up argparse
* Consistent and language-neutral tooling can hide the implementation details of the tool
* Monorepos
  * Different teams/projects can have tools bounded within their respective directories
  * Tool discovery becomes easier for people outside of the team
* Multi-repo
  * Knowing to type `fx` in any repository and having a list of available commands is super developer friendly
    * This can be extended further by having consistent commands like `build`, `test` and `start`

## Configuration

fx relies on two types of configurations — known as descriptors: workspace and command. If you can understand protobufs, it might be easier to directly check the [descriptor](src/protobuf/fx/descriptor/v1beta/descriptor.proto).

### Workspace Descriptor

Creating a `workspace.fx.yaml` file creates a fx workspace and defines the root of the project. `workspace.fx.yaml` conforms to a `FxWorkspaceDescriptor`.

#### FxWorkspaceDescriptor

* __descriptor_version__
  * `Type: string` · `Default: ""` · `required`
  * The workspace descriptor version. Currently only "v1beta" is supported.
* __ignore__
  * `Type: List<string>` · `Default: []` · `optional`
  * List of directories to ignore when searching for commands within the workspace.

__Example:__
```yaml
# ~/acme-corp/workspace.fx.yaml

descriptor_version: v1beta
ignore:
  - node_module
  - test
```

### Command Descriptor

Creating a `command.fx.yaml` file creates a fx command within the workspace.

All commands defined in the workspace will have a name with respect to the location of the workspace descriptor. For example, if a workspace is defined in `~/acme-corp/workspace.fx.yaml`, a command defined in sub folder will create commands:

* ~/acme-corp/__<ins>setup</ins>__/command.fx.yaml → creates `fx setup`
* ~/acme-corp/__<ins>tools/example</ins>__/command.fx.yaml → creates `fx tools/example`
* ~/acme-corp/__<ins>tools/example/another</ins>__/command.fx.yaml → creates `fx tools/example/another`

`command.fx.yaml` conforms to a `FxCommandDescriptor`.

#### FxCommandDescriptor

* __descriptor_version__
  * `Type: string` · `Default: ""` · `required`
  * The command descriptor version. Currently only "v1beta" is supported.
* __synopsis__
  * `Type: string` · `Default: ""` · `required`
  * A one line description of the command. This will be used when listing the command via `fx list`.
* __description__
  * `Type: string` · `Default: ""` · `optional`
  * Detailed description of the command.
* __options__
  * `Type: List<OptionDescriptor>` · `Default: []` · `optional`
  * The accepted command options.
* __arguments__
  * `Type: List<ArgumentDescriptor>` · `Default: []` · `optional`
  * The accepted command arguments. The order of the arguments are important as they will be parsed in order.
* __runtime__
  * `Type: RuntimeDescriptor` · `Default: null` · `required`
  * The command runtime information used internally by fx.

__Example:__
```yaml
# ~/acme-corp/example/command.fx.yaml

descriptor_version: v1beta
synopsis: An example command for testing.
description: >
  This is an example commmand to test fx in development mode. This is intentionally a very long description with multiple paragraphs.

  Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean eget ex egestas, ultrices sapien et, elementum nisl. Aenean risus leo, ultrices nec tempor in, aliquam dignissim lorem. Maecenas sed pharetra felis. Vivamus sed aliquam justo, ut accumsan mi. Aliquam tincidunt pulvinar lacinia. Vestibulum malesuada leo quis interdum ornare. Mauris malesuada vitae dolor eget aliquam. Aliquam dapibus in lorem sit amet egestas. Sed feugiat neque nec pretium posuere.
options: []
arguments: []
runtime:
  run: run: python3 $FX_WORKSPACE_DIRECTORY/example/main.py
```

#### OptionDescriptor

* __name__
  * `Type: string` · `Default: ""` · `required`
  * The name of the option used in the command invocation. i.e. --test, --json, etc. Option names are unique per command. Usually this is lower cased and in kebab-case. Do not include the "--" prefix.
* __short_name__
  * `Type: string` · `Default: ""` · `optional`
  * A single letter alias of the option used in the command invocation. i.e. -t, -j, etc. Usually this is the first letter of the name. Do not include the "-" prefix.
* __description__
  * `Type: string` · `Default: ""` · `required`
  * Detailed description of the option.
* __[bool, int, double, string]\_value__
  * The value type accepted by the option.
  * One of the following is required:
    * __bool_value__
      * `Type: BoolValueDescriptor` · `Default: null`
      * Accept a boolean value.
    * __int_value__
      * `Type: IntValueDescriptor` · `Default: null`
      * Accept an int value.
    * __double_value__
      * `Type: DoubleValueDescriptor` · `Default: null`
      * Accept a double value.
    * __string_value__
      * `Type: StringValueDescriptor` · `Default: null`
      * Accept a string value.

__Example:__
```yaml
descriptor_version: v1beta
synopsis: An example command for testing.
options:
  - name: bool-example
    short_name: b
    bool_value: {}
  - name: int-example
    short_name: i
    int_value:
      default: 416
  - name: double-example
    short_name: d
    double_value:
      list: true
  - name: string-example
    short_name: s
    string_value:
      choices: [a, b, c, x]
      default: x
```

#### ArgumentDescriptor

* __name__
  * `Type: string` · `Default: ""` · `required`
  * The name of the argument. The name is used internally to differentiate positional arguments and in the command help menu.
* __description__
  * `Type: string` · `Default: ""` · `required`
  * Detailed description of the argument.
* __[int, double, string]\_value__
  * The value type accepted by the argument.
  * To prevent ambiguity, only at most one argument can accept a list for a command. The list argument must be placed last.
  * One of the following is required:
    * __int_value__
      * `Type: IntValueDescriptor` · `Default: null`
      * Accept an int value.
    * __double_value__
      * `Type: DoubleValueDescriptor` · `Default: null`
      * Accept a double value.
    * __string_value__
      * `Type: StringValueDescriptor` · `Default: null`
      * Accept a string value.

__Example:__
```yaml
descriptor_version: v1beta
synopsis: An example command for testing.
arguments:
  - name: number
    int_value:
      default: 416
  - name: precision
    double_value:
      default: 90.5
  - name: files
    string_value:
      list: true
```

#### RuntimeDescriptor

* __run__
  * `Type: string` · `Default: ""` · `required`
  * The command used to invoke the command. The `FX_WORKSPACE_DIRECTORY` environment variable will be injected during invocation. It points to the root directory of the current fx workspace.
    * i.e. Suppose a command exists under tools/builder/main.py. The run command is then: `python3 $FX_WORKSPACE_DIRECTORY/tools/builder/main.py`

__Example:__
```yaml
runtime:
  run: python3 $FX_WORKSPACE_DIRECTORY/tools/builder/main.py
```

#### BoolValueDescriptor

A bool value simply takes an empty object. The default value for a bool is always false.

__Example:__
```yaml
options:
  - name: test
    short_name: t
    description: Some example.
    bool_value: {}
```

#### IntValueDescriptor

* __choices__
  * `Type: List<int>` · `Default: []` · `optional`
  * The accepted choices. If empty, any value is accepted.
* __default__
  * `Type: int` · `Default: ""` · `optional`
  * The default value. If there are choices, the default must be one of the choices.
* __required__
  * `Type: bool` · `Default: false` · `optional`
  * If the value is required.
* __list__
  * `Type: bool` · `Default: false` · `optional`
  * If the value takes a list of values.

__Example:__
```yaml
options:
  - name: test
    short_name: t
    description: Some example.
    int_value:
      choices:
        - 416
        - 905
      default: 416
      required: true
      list: false
```

#### DoubleValueDescriptor

* __choices__
  * `Type: List<double>` · `Default: []` · `optional`
  * The accepted choices. If empty, any value is accepted.
* __default__
  * `Type: double` · `Default: ""` · `optional`
  * The default value. If there are choices, the default must be one of the choices.
* __required__
  * `Type: bool` · `Default: false` · `optional`
  * If the value is required.
* __list__
  * `Type: bool` · `Default: false` · `optional`
  * If the value takes a list of values.

__Example:__
```yaml
options:
  - name: test
    short_name: t
    description: Some example.
    double_value:
      choices:
        - 41.6
        - -9.05
      default: 41.6
      required: true
      list: false
```

#### StringValueDescriptor

* __choices__
  * `Type: List<string>` · `Default: []` · `optional`
  * The accepted choices. If empty, any value is accepted.
* __default__
  * `Type: string` · `Default: ""` · `optional`
  * The default value. If there are choices, the default must be one of the choices.
* __required__
  * `Type: bool` · `Default: false` · `optional`
  * If the value is required.
* __list__
  * `Type: bool` · `Default: false` · `optional`
  * If the value takes a list of values.

__Example:__
```yaml
options:
  - name: test
    short_name: t
    description: Some example.
    string_value:
      choices:
        - abc
        - xyz
      default: abc
      required: true
      list: false
```

## Runtime

fx will handle all the argument parsing and validations based on the command descriptor. Once the arguments are parsed, fx will invoke the underlying command and pass the arguments as a well defined JSON. All options and arguments are guaranteed to exist with valid values. 

The keys of the JSON is the name of the option and arguments. The value of the JSON maps to the value of the option/argument. The value is an dictionary of the form:

  * __value:__ The value of the option/argument. The type corresponds to the specified type.
  * __user_set:__ A boolean value indicating if the option/argument was explicitly set by the user. True implies it was and False implies that it is falling back on some default value.

__Example:__
```python3
import sys
import json

# fx will parse use arguments conforming to the command descriptor and pass the
# results to the underlying command as a well defined JSON blob.
args = json.loads(sys.argv[1])

for name in args:
  value = args[name].value
  user_set = args[name].user_set
  print(f"{name} = {value} | user_set: {user_set}")
```

## FAQs

* How do I create subcommands?
  * Since fx commands map to the folder layout/depth, simply create a folder within your command and define a command descriptor. i.e. `foo/backend/setup`, `foo/backend/start`, `foo/backend/migrate` 

## Development

### Setup

fx is built using [Bazel](https://bazel.build/). Everything required to develop fx is configured through Bazel — including clang tools (i.e. tidy, format). To ensure further hermetic builds, the Bazel version itself is [pinned](.bazelversion). Instead of manually installing Bazel, it is recommended to install [Bazelisk](https://github.com/bazelbuild/bazelisk). Bazelisk is a Bazel version manager and launcher:

* macOS: `brew install bazelisk`
* other: `go get github.com/bazelbuild/bazelisk`

### Frequently Used Commands

```bash
# Run in development mode.
$ bazel run //:fx -- <args...>

# Run in production mode.
$ bazel run --config release //src:main -- <args...>

# Run all tests.
$ bazel test //...

# Run formatting and code analysis.
#
# As buildifier, clang-tidy and clang-format are built from source, this will
# initially take some time. Subsequent runs will be immediate.
$ fx tools/format --help
```

### Third Party Libraries

* Please see [third_party](third_party) for examples of including third party libraries via Bazel
* [boost](http://boost.org/) is available via `@boost`. Run `bazel query @boost//...` to see available targets

--------------------------------------------------------------------------------
February 2022 — San Francisco
