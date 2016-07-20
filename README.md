# nerves_io_nfc

Nerves support for libnfc-compatible USB NFC readers.

## Limitations

Furthermore, this library currently only reads the tag UID of Mifare tags. The LibNFC supports reading and writing MIFARE tag data, but this library does not yet support it. Pull requests welcome!


## Installation

  1. Add `nerves_io_nfc` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:nerves_io_nfc, "~> 0.1.0"}]
    end
    ```

  2. Ensure `nerves_io_nfc` is started before your application:

    ```elixir
    def application do
      [applications: [:nerves_io_nfc]]
    end
    ```

## Usage

Add the `Nerves.IO.NFC` GenServer to your supervision tree:

    worker(Nerves.IO.NFC, [{RfidReader.Handler, :tag_scanned}])

When a tag is scanned the function `RfidReader.Handler.tag_scanned()`
function will now be called with the hex-encoded serial number (UID)
of the scanned tag as its single argument.

Note: the USB needs to be plugged in before the application starts.
USB hot-plugging is currently not supported.
