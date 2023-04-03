# multiple-monitors-scratchpad
A workaround for lacking scratchpad functionality in i3 when using multiple monitors

## Usage
TIP: For help run the script with the `--help` option.

Run the script with parameters to define the size and position of your scratchpad, as well as the behavior for selecting the monitor where it should appear.

Here is an example of a pop-up terminal. The width, height and gaps are set in % of monitor width/height, but you can use `px` instead of `ppt` to set the values in pixels. You can use floating point values as well.

`multiple-monitors-scratchpad.sh --width 100ppt --height 46ppt --vgap bottom2.4ppt --selector 'instance="term-scratchpad"'`

Start an instance of a terminal emulator beforehand:

`alacritty --class term-scratchpad`


### Options

- `-s | --selector`
Required. Requires a parameter in the form of an i3 selector.
See the i3 docs for possible selectors.

Example: `--selector "instance=<your-instance>"`


- `-w | --width`
Optional. Sets the width of the scratchpad.

Example: `--width 99.4ppt`
Default value: `100ppt`


- `-h | --height`
Optional. Sets the height of the scratchpad.

Example: `--height 46.7ppt`
Default value: `46ppt`


- `-n | --hgap`
Optional. Sets the horizontal gap either from the left or the right edge of the monitor.

Example: `--hgap left50px`
Default value: `left0ppt`


- `-v | --vgap`
Optional. Sets the vertical gap either from the top or the bottom edge of the monitor.

Example: `--vgap bottom3.2ppt`
Default value: `bottom2.4ppt`


- `-f | --use-window-focus`
Optional. Use this option to show the scratchpad on the monitor closest to the center of the currently focused window.

Default behavior: Show the scratchpad on the monitor where the mouse is.

### Special Options
When providing a special option, no other options are required.

- `--help`
Show help. 


- `-c | --print-cache`
This option boosts the scripts performance. Use this if you notice a delay between running the script and the scratchpad showing. This option prints information that the script obtains through expensive commands. Put the output into the environment variable `SP_CACHE`, then the script skips the expensive commands and reads the cache instead. NOTE: Everytime your screen layout changes, you need to set `SP_CACHE` again. This includes changes in resolution, changes in connected monitors and changes in the position of the monitors in the screen space.
