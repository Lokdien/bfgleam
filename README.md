# bfinterpreter

I made this brainfuck interpreter as a starting project for learning functionnal programming.

```gleam
pub fn main() {
  let file_path = "examples/helloworld.b"

  let assert Ok(True) = simplifile.verify_is_file(file_path)
  let assert Ok(code) = simplifile.read(file_path)
  run(Program(code, Memory([], 0, [])))
}
```

## Development

```sh
gleam run   # Run the project
```
