# Praat Script Interpreter

The PraatInterpreter provides a persistent Praat scripting environment
within R. Unlike one-shot script execution, the interpreter maintains
state between calls, enabling incremental script development and
interactive exploration.

## Value

An R6 object of class `PraatInterpreter`.

## Details

R6 class for executing Praat scripts with persistent interpreter state.
Allows running multiple scripts while maintaining variables and state
between runs. Provides bidirectional object transfer between R and
Praat's object list.

## See also

[`Sound`](https://humlab-speech.github.io/pladdrr/reference/Sound.md),
[`Pitch`](https://humlab-speech.github.io/pladdrr/reference/Pitch.md)
for Praat object classes

## Methods

### Public methods

- [`PraatInterpreter$new()`](#method-PraatInterpreter-initialize)

- [`PraatInterpreter$run()`](#method-PraatInterpreter-run)

- [`PraatInterpreter$get_variable()`](#method-PraatInterpreter-get_variable)

- [`PraatInterpreter$set_variable()`](#method-PraatInterpreter-set_variable)

- [`PraatInterpreter$eval()`](#method-PraatInterpreter-eval)

- [`PraatInterpreter$object_count()`](#method-PraatInterpreter-object_count)

- [`PraatInterpreter$list_objects()`](#method-PraatInterpreter-list_objects)

- [`PraatInterpreter$get_object()`](#method-PraatInterpreter-get_object)

- [`PraatInterpreter$get_object_by_id()`](#method-PraatInterpreter-get_object_by_id)

- [`PraatInterpreter$set_object()`](#method-PraatInterpreter-set_object)

- [`PraatInterpreter$remove_object()`](#method-PraatInterpreter-remove_object)

- [`PraatInterpreter$remove_object_by_id()`](#method-PraatInterpreter-remove_object_by_id)

- [`PraatInterpreter$select_object()`](#method-PraatInterpreter-select_object)

- [`PraatInterpreter$clear_objects()`](#method-PraatInterpreter-clear_objects)

- [`PraatInterpreter$print()`](#method-PraatInterpreter-print)

- [`PraatInterpreter$clone()`](#method-PraatInterpreter-clone)

------------------------------------------------------------------------

### `PraatInterpreter$new()`

Create a new interpreter instance with empty state.

#### Usage

    PraatInterpreter$new()

------------------------------------------------------------------------

### `PraatInterpreter$run()`

Execute Praat script code.

#### Usage

    PraatInterpreter$run(script)

#### Arguments

- `script`:

  Character string with Praat script.

#### Returns

Self (invisibly), for method chaining.

------------------------------------------------------------------------

### `PraatInterpreter$get_variable()`

Get a variable's value from the interpreter.

#### Usage

    PraatInterpreter$get_variable(name)

#### Arguments

- `name`:

  Variable name.

#### Returns

Variable value.

------------------------------------------------------------------------

### `PraatInterpreter$set_variable()`

Set a variable's value in the interpreter.

#### Usage

    PraatInterpreter$set_variable(name, value)

#### Arguments

- `name`:

  Variable name.

- `value`:

  Variable value.

#### Returns

Self (invisibly).

------------------------------------------------------------------------

### `PraatInterpreter$eval()`

Evaluate a Praat expression and return the result.

#### Usage

    PraatInterpreter$eval(expression)

#### Arguments

- `expression`:

  Praat expression.

#### Returns

Result of the expression.

------------------------------------------------------------------------

### `PraatInterpreter$object_count()`

Get the count of objects in the Praat object list.

#### Usage

    PraatInterpreter$object_count()

#### Returns

Integer count.

------------------------------------------------------------------------

### `PraatInterpreter$list_objects()`

List all objects in the Praat object list.

#### Usage

    PraatInterpreter$list_objects()

#### Returns

A data.frame with id, name, class, and selected columns.

------------------------------------------------------------------------

### `PraatInterpreter$get_object()`

Get a Praat object from the interpreter's object list.

#### Usage

    PraatInterpreter$get_object(name, type = NULL)

#### Arguments

- `name`:

  Object name.

- `type`:

  Expected type (optional).

#### Returns

An R6 object.

------------------------------------------------------------------------

### `PraatInterpreter$get_object_by_id()`

Get a Praat object by ID.

#### Usage

    PraatInterpreter$get_object_by_id(id)

#### Arguments

- `id`:

  Object ID.

#### Returns

An R6 object.

------------------------------------------------------------------------

### `PraatInterpreter$set_object()`

Add an R object to Praat's object list.

#### Usage

    PraatInterpreter$set_object(name, object)

#### Arguments

- `name`:

  Object name.

- `object`:

  A PraatObject.

#### Returns

Object ID (invisibly).

------------------------------------------------------------------------

### `PraatInterpreter$remove_object()`

Remove an object from Praat's object list by name.

#### Usage

    PraatInterpreter$remove_object(name)

#### Arguments

- `name`:

  Object name.

#### Returns

Self (invisibly).

------------------------------------------------------------------------

### `PraatInterpreter$remove_object_by_id()`

Remove an object from Praat's object list by ID.

#### Usage

    PraatInterpreter$remove_object_by_id(id)

#### Arguments

- `id`:

  Object ID.

#### Returns

Self (invisibly).

------------------------------------------------------------------------

### `PraatInterpreter$select_object()`

Select an object in Praat's object list.

#### Usage

    PraatInterpreter$select_object(name, add = FALSE)

#### Arguments

- `name`:

  Object name.

- `add`:

  If TRUE, add to the current selection.

#### Returns

Self (invisibly).

------------------------------------------------------------------------

### `PraatInterpreter$clear_objects()`

Clear all objects from Praat's object list.

#### Usage

    PraatInterpreter$clear_objects()

#### Returns

Self (invisibly).

------------------------------------------------------------------------

### `PraatInterpreter$print()`

Print a summary of the interpreter's current object list.

#### Usage

    PraatInterpreter$print()

#### Returns

Self (invisibly).

------------------------------------------------------------------------

### `PraatInterpreter$clone()`

The objects of this class are cloneable with this method.

#### Usage

    PraatInterpreter$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
# Create interpreter
interp <- PraatInterpreter$new()

# Execute script
interp$run("
  Create Sound as pure tone: \"tone\", 1, 0, 1, 44100, 440, 0.2, 0.01, 0.01
  pitch = To Pitch: 0, 75, 600
")

# Get objects
interp$list_objects()
#>   id       name class selected
#> 1  1 Sound tone Sound    FALSE
#> 2  2 Pitch tone Pitch     TRUE
sound <- interp$get_object("tone")

# Set and get variables
interp$set_variable("freq", 440)
interp$get_variable("freq")
#> [1] 440

# Evaluate expressions
interp$eval("sqrt(2)")
#> [1] 1.414214
```
