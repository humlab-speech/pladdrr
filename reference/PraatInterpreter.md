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

## Methods

- `new()`:

  Create new interpreter instance with empty state

- `run(script)`:

  Execute Praat script code, returns self for chaining

- `get_variable(name)`:

  Get variable value from interpreter

- `set_variable(name, value)`:

  Set variable value in interpreter

- `eval(expression)`:

  Evaluate expression and return result

- `object_count()`:

  Get count of objects in Praat object list

- `list_objects()`:

  List all objects (returns data.frame)

- `get_object(name, type)`:

  Get Praat object from interpreter's list

- `get_object_by_id(id)`:

  Get Praat object by ID

- `set_object(name, object)`:

  Add R object to Praat's object list

- `remove_object(name)`:

  Remove object by name

- `remove_object_by_id(id)`:

  Remove object by ID

- `select_object(name, add)`:

  Select object in Praat's list

- `clear_objects()`:

  Clear all objects from list

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

#### Usage

    PraatInterpreter$new()

------------------------------------------------------------------------

### `PraatInterpreter$run()`

#### Usage

    PraatInterpreter$run(script)

------------------------------------------------------------------------

### `PraatInterpreter$get_variable()`

#### Usage

    PraatInterpreter$get_variable(name)

------------------------------------------------------------------------

### `PraatInterpreter$set_variable()`

#### Usage

    PraatInterpreter$set_variable(name, value)

------------------------------------------------------------------------

### `PraatInterpreter$eval()`

#### Usage

    PraatInterpreter$eval(expression)

------------------------------------------------------------------------

### `PraatInterpreter$object_count()`

#### Usage

    PraatInterpreter$object_count()

------------------------------------------------------------------------

### `PraatInterpreter$list_objects()`

#### Usage

    PraatInterpreter$list_objects()

------------------------------------------------------------------------

### `PraatInterpreter$get_object()`

#### Usage

    PraatInterpreter$get_object(name, type = NULL)

------------------------------------------------------------------------

### `PraatInterpreter$get_object_by_id()`

#### Usage

    PraatInterpreter$get_object_by_id(id)

------------------------------------------------------------------------

### `PraatInterpreter$set_object()`

#### Usage

    PraatInterpreter$set_object(name, object)

------------------------------------------------------------------------

### `PraatInterpreter$remove_object()`

#### Usage

    PraatInterpreter$remove_object(name)

------------------------------------------------------------------------

### `PraatInterpreter$remove_object_by_id()`

#### Usage

    PraatInterpreter$remove_object_by_id(id)

------------------------------------------------------------------------

### `PraatInterpreter$select_object()`

#### Usage

    PraatInterpreter$select_object(name, add = FALSE)

------------------------------------------------------------------------

### `PraatInterpreter$clear_objects()`

#### Usage

    PraatInterpreter$clear_objects()

------------------------------------------------------------------------

### `PraatInterpreter$print()`

#### Usage

    PraatInterpreter$print()

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
