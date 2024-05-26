import gleam/bit_array
import gleam/erlang
import gleam/io
import gleam/list
import gleam/string
import simplifile

pub type Program {
  Program(code: String, mem: Memory)
}

pub type Memory {
  Memory(before: List(Int), current: Int, after: List(Int))
}

fn increase(mem: Memory) -> Memory {
  Memory(..mem, current: mem.current + 1)
}

fn decrease(mem: Memory) -> Memory {
  Memory(..mem, current: mem.current - 1)
}

fn forward(mem: Memory) -> Memory {
  case list.first(mem.after) {
    Ok(x) -> Memory([mem.current, ..mem.before], x, list.drop(mem.after, 1))
    _ -> Memory([mem.current, ..mem.before], 0, list.drop(mem.after, 1))
  }
}

fn backward(mem: Memory) -> Memory {
  case list.first(mem.before) {
    Ok(x) -> Memory(list.drop(mem.before, 1), x, [mem.current, ..mem.after])
    _ -> Memory(list.drop(mem.before, 1), 0, [mem.current, ..mem.after])
  }
}

fn output(mem: Memory) -> Memory {
  io.print(case bit_array.to_string(<<mem.current>>) {
    Ok(x) -> x
    _ -> "[Error] Invalid character"
  })
  mem
}

fn input(mem: Memory) -> Memory {
  case erlang.get_line(">") {
    Ok(c) ->
      case list.first(string.to_utf_codepoints(c)) {
        Ok(n) -> Memory(..mem, current: string.utf_codepoint_to_int(n))
        _ -> mem
      }
    _ -> mem
  }
}

fn drop_loop(code: String, depth: Int) -> String {
  case string.pop_grapheme(code), depth {
    Ok(_), 0 -> code
    Ok(#("[", next_instructions)), _ -> drop_loop(next_instructions, depth + 1)
    Ok(#("]", next_instructions)), _ -> drop_loop(next_instructions, depth - 1)
    Ok(#(_, next_instructions)), _ -> drop_loop(next_instructions, depth)
    _, _ -> ""
  }
}

fn loop(prg: Program) -> Program {
  case prg.mem.current {
    0 -> Program(..prg, code: drop_loop(string.drop_left(prg.code, 1), 1))
    _ ->
      Program(
        ..run(Program(..prg, code: string.drop_left(prg.code, 1))),
        code: prg.code,
      )
  }
}

pub fn dump(mem: Memory) -> List(Int) {
  list.concat([list.reverse(mem.before), [mem.current], mem.after])
}

pub fn run(prg: Program) -> Program {
  case string.pop_grapheme(prg.code) {
    Ok(#("+", next_instructions)) ->
      run(Program(next_instructions, increase(prg.mem)))
    Ok(#("-", next_instructions)) ->
      run(Program(next_instructions, decrease(prg.mem)))
    Ok(#(">", next_instructions)) ->
      run(Program(next_instructions, forward(prg.mem)))
    Ok(#("<", next_instructions)) ->
      run(Program(next_instructions, backward(prg.mem)))
    Ok(#(".", next_instructions)) ->
      run(Program(next_instructions, output(prg.mem)))
    Ok(#(",", next_instructions)) ->
      run(Program(next_instructions, input(prg.mem)))
    Ok(#("[", _)) -> run(loop(prg))
    Ok(#("]", _)) -> prg
    Ok(#(_, next_instructions)) -> run(Program(next_instructions, prg.mem))
    _ -> prg
  }
}

pub fn main() {
  let file_path = "examples/gameoflife.b"

  let assert Ok(True) = simplifile.verify_is_file(file_path)
  let assert Ok(code) = simplifile.read(file_path)
  run(Program(code, Memory([], 0, [])))
}
