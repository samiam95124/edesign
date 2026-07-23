# ICD — Integrated Circuit Designer — User's Manual

> **Recovered document.** This Markdown was extracted from `icduser.dwp`, a
> **DeScribe Word Processor** file (DeScribe, Inc.; document dated
> November 22, 1995). DeScribe stored the body text as near-plain runs, so the
> prose is recovered in full; the original *formatting* (fonts, bold, page
> layout, figures) is not. The text is reproduced **as authored**, including
> period spellings ("allways", "demensions", "heyarchy", "SCEMATIC", ...). The
> reference tables were reconstructed from the flattened text stream; where a
> cell was dropped in extraction it is noted inline. The `.dwp` original is kept
> alongside this file.

---

## OVERVIEW

MOORE/ICD stands for the Integrated Circuit Designer. It is the first true single unit ingrated circuit design program created specifically for the PC/386 computer. Although the target audiance for ICD is not nessarily experenced IC designers, ICD offers the functionallity of software packages formerly offered only on workstations, and for total costs in the six figures.

## EQUIPMENT

MOORE/ICD requires the following equipment at minimum:

- 386/486 ISA/EISA computer.
- 8MB of expanded memory (16MB preferred).
- 387 numeric coprocessor or 486.
- 1024x768 16 color display (XGA, S-VGA or similar).
- 13" wide 7 color printer.
- MS-DOS 4.0 or later.
- A graphics entry tablet (Summagrphics or compatible).

## INVOCATION

ICD is invoked with the simple MS-DOS command line:

```
ICD ⏎
```

ICD allways begins in the schematic edit mode.

## SCEMATIC EDIT

### FORMAT OF SCHEMATIC SHEET

When a new sheet is opened for edit, ICD presents a default view in "realspace". The upper left hand corner is coordinates (0,0) in that space. All measurements in ICD are presented in the SI or metric system. ICD may represent sheets xx meters on a side, obviously somewhat larger than what will be required in common use.

ICD uses what is called a "bounding box" to determine what it considers to be the schematic. The bounding box is the smallest rectangle that will encompass all elements drawn on the schematic. Commonly, the user will use a "frame" for the schematic to show where the bounding box is. This is simply a drawn box within which the schematic is drawn, and can be a simple box, or a complex frame with cross indexing and a title box.

It is recommended that the bounding box be placed at (0,0) (the origin). This way, the position indicator, which displays the (x,y) position in realspace will also display the position within the schematic sheet.

### THE SCHEMAT DISPLAY

This display consists of the drawing area, the menu area(s), and the "target". The drawing area is your "viewport" on SCHEMAT realspace. The menu area(s) contain the "buttons" and other messages that control ICD. Finally the target display shows you the relative position of the bounding box to the viewport.

Moving the graphics tablet "puck" about the tablet surface, the cursor crosshair will be seen to follow. This is a magenta cross that will be referred to simply as "the cursor". The cursor cross is allways present (unless "out of proximity"), and allways has the same appearance so that you may get used to watching it move. When the cursor is in the viewport or target, the position display will be active. This indicates the (x,y) position of the cursor in realspace (regardless of where the viewport itself lies). If the schematic sheet origin corresponds to realspace (0,0), the position will also reflect the distance from the left (x) and top (y) sides of the sheet. When the cursor leaves the viewport or target, the position display will go blank, indicating that the cursor position is undefined.

The PROXIMTY button indicates when the puck is in the proper area of the graphics tablet and in "in contact" with the surface of the tablet. Typically, the puck can be as much as 2cm or more above the tablet and still have valid proximity. When the puck is not in proximity, the proximity indicator turns red, and the cursor cross disappears. The tablet may also have a flashing light or other indicator for this. The display will return to normal as soon as the puck returns to proimity.

As the cursor crosses the menu area(s), when an "active" button is crossed, it changes to a bright yellow color. This means that the button is ready to be activated with a puck button push. Buttons that are active are normally colored green.

Puck buttons are specified in Fig. xx. We describe the buttons as PB1, PB2, PB3 and PB4 (Puck Button 1-4). Note that the button numbering scheme does not nessarily match the numbering scheme specified in the graphics tablet operator's manual. These buttons generally function as follows:

| Button | Function |
|--------|----------|
| PB1 | Activate button or begin sequence. |
| PB2 | End sequence, place text entry cursor. |
| PB3 | *(description dropped in extraction)* |
| PB4 | Cancel operation. |

Some commands in ICD are usable in "drag" mode. Using this mode, a puck button is pressed, held and the puck moved. ICD detects puck movement with a button down. It is not important how long the button is down, only if the puck is moved while a button is down. In addition, the puck must move a minimum distance (five screen pixels) to be detected as a drag. This is to prevent false drag indications.

A special button is a "value" button. These buttons contain a sequence of up to 8 characters/numbers, and can be modified by keyboard entry. To modify a value button, first select it (place the cursor over it, and it lights up yellow), then click PB1 where you wish to enter characters. The cursor will appear there. The character entry cursor is a red vertical line that lies between two characters. The entry cursor is not the same as the puck cursor, and will stay where it was set no matter what the puck cursor does. The cursor can be moved to a different location by repeating the click PB1. The next character typed will be placed at the right of the cursor line. These characters are valid during a value button edit:

| Key | Action |
|-----|--------|
| Left arrow | Moves the cursor one character left, unless already at the left side of the button. |
| Right arrow | Moves the cursor one character right, unless already at the right side of the button. |
| Insert | Clears the button and positions the cursor to the left side of the button. |
| Tab | Restores the button to its "default" value. This is determined for each button individually. |
| Back arrow | Deletes the last character (character to the right of the cursor), and moves the cursor one character left. |
| Delete | Deletes the next character (character to the left of the cursor). |
| Return | Enters the current value of the button. |

Characters may be typed into the button, and if any characters are to the right of the cursor, they will be moved right. The return key completes the entry and removes the cursor.

### SPECIFING, LOADING AND SAVING A SCHEMATIC SHEET

The current file button contains the name of the currently loaded file. When ICD starts up, a blank sheet will appear by default. Editting the filename button will define the name of that sheet, which can then be saved or loaded.

When the filename is defined, the cell name field is automatically defined to be the same name. When a new file is created, it automatically contains at least one cell by the same name. This is the "top" cell in the file.

Loading a file when the name field is defined is done by PB1 when the load button is selected. The contents of the file in the current directory will replace the current file.

Saving a file is done by PB1 with load selected. The current file will be saved to the current directory under the given name. The file in the current directory will be the file by the specified name with the extention ".cel" appended.

The current sheet can be flushed, and a new (blank) sheet started with PB1/NEWFILE. The contents of the current file will be lost.

Filenames can also be specified by picking from a list of files in the current directory. PB1/FILES replaces the viewport with a directory of files avalible in the current directory. The cursor may select these files as any other button, and PB1 and the file button will cause the file to be loaded, and displayed, and the name to be set as the filename and top cell name. The viewport will revert to normal.

The files directory can be stopped and the viewport returned to normal by PB4, PB1/FILES, or ESC on the keyboard.

When a new file is loaded, and the top sheet is not blank, the viewport is automatically set to the bounding box of the sheet as specified above.

### CELLS, CELL SPECIFICATION

A file is a collection of "cells", each of which contains a collection of design data. At minimum, the cell of the same name as the file must be present. This is allways the sheet displayed by default when a file is loaded.

A "sheet", in this case a schematic sheet, is the design data for the schema section of ICD. The heyarcy is then: files contain one or more cells, which contain a number of sheets or other design data.

Cell names must be distinct, and cells do not nest.

Cells are specified by editting the cell name button. If the name specified is that of an existing cell, that cell is displayed. If not, a new cell is opened and given that name.

The current cell can be flushed and a new cell begun by PB1/NEWCELL. The previous contents of the cell are lost.

Cellnames can also be specified by a directory of cells in the current file. PB1/CELLS replaces the viewport with a directory of cells available. The cursor may select these files, and PB1 and the cell button will cause that cell to be displayed, and the name to appear in the cell name button.

### CHANGING THE VIEWPORT

The viewports location in realspace appears in the ORG X and Y buttons, and the current view scale in the SCALE button. The origin is the location in realspace of the upper left hand corner of the viewport. The scale indicates how many times larger the viewport is than 1:1, an arbitrary zoom factor that represents the maximum magnification ICD is capable of. At 1:1, the viewport convers xx mm in x and xx mm in y, so there is plenty of room to zoom into the schematic.

The simplest viewport change is the PAN function. Activate this mode with PB1/PAN, then move the cursor to a point of reference on the schematic and hit PB1. This is the "old" point, and a "compass rose" will appear there. The cursor is then moved to the new point, and then PB2 hit. The viewport will be moved such that the first point will be moved to the second point.

Alternately, we may "drag" the pan. In this mode, hit PB1 to locate the cross, but hold the button down move it to the new location and then release. This will then be the new point.

The IN function will zoom in to a given area of the schematic. Activate with PB1/IN. Then specify a "view box" by PB1 next to the area of interest. This may be also dragged by holding the button. When the puck is moved, a view box will be outlined in blue, which indicates the area of interest on the schematic. The puck is moved so that the box encompasses the area of interest, and then PB2 or PB1 released. The viewport will then change to be the closest possible to the indicated box.

Appearing with the view box during the IN operation is an "aspect" box outlined in green. When you specify a view box, the actual viewport must be a rectangle that matches the aspect ratio of the viewport section (which is approximately 4:3, the same as the whole display). The aspect box, then, is showing exactly the region of the schematic that will actually appear in the viewport after the zoom operation.

The OUT function is the logical opposite of IN. It creates a larger viewport of the schematic. The OUT function is not as intuitive as the IN function, because the prospective viewport does not appear on the screen. The OUT function is executed just as for the IN function. Activate with PB1/OUT, then specify a "view box" by PB1. This time, the view box indicates where the current viewport will be in the new viewport. In other words, the current view of the schematic will be shrunk to fit into the view box, enlarging the view of the schematic. As in IN, a green aspect box indicates the actual form of the viewport that will result from the specified view box.

The FULL function, activated by PB1/FULL, changes the viewport to the closest view that will encompasses the bounding box for the schematic (just as when the schematic is first called up). This is the simplest way to "back up" and view all of your schematic. It may be more convienent at times to use the FULL function to back up, and then the IN function to specify a specific area, rather than use the OUT function. This function does nothing if no schematic elements have been drawn on the schematic.

The BACK function is activated by PB1/BACK. This function restores the last view of the schematic. It is remembers one view, so that hitting BACK repeatedly will switch between the current and last views. The BACK function has great practical use when performing schematic edits. When editing a section, you can zoom in to a small section, make a modification, then BACK out to the original view again, etc.

Sometimes may need to jump back and forth between complex views in a complex way. An example is when you are doing detail work on several close in sections of the schematic (as in wiring two small sections together at opposite sides of the schematic). For this we provide a set of "radio" buttons under the FULL and BACK buttons, labeled A thru H (8 buttons). Each of these buttons can store a view. To store a view in a view button, use PAN, IN, OUT, FULL or BACK to specify a view. Then press PB2 and the button, A thru H. The button will turn green to indicate that a view is stored there (if the button was "empty" before). To activate a stored view, press PB1 and the view button. That view will then become active.

Finally, it is possible to directly specify the X, Y position and scale of the viewport. To do this, the ORG X, ORG Y and SCALE value fields. After the field has been changed, the viewport will be changed to match. This function will rarely be required, but can be usefull if you need to view a section whose exact location is known.

### USING THE TARGET DISPLAY

The target display, in the upper right of the SCHEMA display, is an alternate way of specifing and reading the location of the viewport. The target provides a iconic view of the viewport and the schematic bounding box. In the target, you will see two objects. A grey solid box and a brown rectangle. The grey box indicates the schematic bounding box (and will not appear if the schematic is blank). The brown rectange represents the viewport. The target is kind of a "master view" of the entire realspace in SCHEMA. Both the schematic elements and your view are allways shown, even if you are lost and the viewport is far from the schematic bounding box. After using the FULL function (or upon first calling up a schematic), note that the brown box just encompasses the grey schematic sheet. After an IN function, you will see the brown viewport box inside the grey box, showing you what part of the schematic you are currently looking at. If you move the viewport away from the schematic sheet, you will see the brown box and the grey box side by side, indicating that the viewport no longer contains any part of the schematic.

But the target is more than an interesting display. The PAN and IN functions (which allow the direct specification of the viewport box) will also work on the target. The OUT function is unessessary on the target, as we will see.

The IN function works in the target just as in the viewport. Hit PB1/IN. Locate the starting point in the target, start the box by PB1, and end with a drag or PB2. The same view box and aspect box will appear. The difference between doing this on the target and on the viewport is that on the target you are working on a symbolic version of the schematic, and you must keep a mental image of its contents.

The reason that the IN function can do both the functions of IN and OUT is that the target view allways keeps everything on the sheet within the target. You can therefore allways draw a box around the area of interest.

The PAN function also operates the same. Press BP1/PAN to select, and PB1 place the compass on the target. Then the new location is specified with either a drag or PB2.

### THE BORDER

The first order of business when beginning a new schematic is to establish the border. The border establishes the bounding box, and essentially establishes ICD's idea of where the schematic is in real space. It establishes the format of the printed/ploted sheet, and the FULL view.

ICD will establish the bounding box by default (by finding the smallest rectangle that contains the object you have drawn), but you will find it is more convenient to specify this before beginning the draw. Since the border will define what is printed, it will also define the basic demensions of the schematic sheet.

There is no automatic border placement in ICD. Drawing the border is a user specified function. You may either draw the border directly on the schematic sheet, or call up a predefined border as a cell. The border can be as simple as a box drawn around the schematic sheet, or complex with cross referencing and title block.

ICD comes with a set of sheet borders, in the sizes A thru E, and also an "adjusted" version of the same. These are, in metric:

| Size | Dimensions | Aspect ratio |
|------|------------|--------------|
| A | 216mm x 280mm | 1.3 |
| B | 280mm x 432mm | 1.5 |
| C | 432mm x 556mm | 1.3 |
| D | 556mm x 864mm | 1.5 |
| E | 864mm x 1118mm | 1.3 |

*(The size-letter column above was dropped in extraction and is restored from the surrounding text, which names the sizes "A thru E".)*

This drafting system was designed so that each size can be folded once to equal the next smaller size, so that E folds to D folds to C folds to B folds to A. In the days of electronic drafting and reducing copy machines a more important factor is the "aspect ratio" of a schematic, or the ratio of its width to height. Two sizes that have the same aspect ratio can be reduced or enlarged to equal each other. So E can be reduced to C, which can be reduced to A. D can be reduced only to B.

ICD may perform any given scaling when the sheet is printed. It works best, however, for you to plan on printing your sheets at the same scale as you draft them (or, draft at the same size as you print). This gives you "what you see is what you get" drafting, including being able to match ICD's demension readings on the printout with a ruler. In addition, the standard devices are approximately sized to ANSI Y32.14 half-size symbols if the print size matches the drawing size.

Besides the standard sheet sizes, I have provided a set of special sizes, with properties that are especially convenient for electronic schematic drafting under ICD. These sizes are:

| Size | Dimensions | Aspect ratio |
|------|------------|--------------|
| AX | 210mm x 270mm | 1.3 |
| BX | 270mm x 360mm | 1.3 |
| CX | 330mm x 420mm | 1.3 |
| DX | 540mm x 720mm | 1.3 |
| EX | 870mm x 1110mm | 1.3 |

*(As above, the AX–EX size-letter column is restored from context.)*

There are two main features of these sizes. First, of them have approximately the same aspect ratio, which means that any given size can be reduced or enlarged to any other size. This also means that the B and D sizes will be narrower than the standard sizes. Second, all demensions are even multiples of 30mm, which is the default grid size in ICD. This a very desirable feature for laying out schematics and cross references.

The sizes are deliberately chosen so that they can be reduced to AX size, and that size closely matches a standard A sheet. This means that all schematics can be reduced to notebook or large manual size.

Some comments are in order on each size:

#### AX SHEET

This size may require some slight reduction to print on 8.5 in. wide printers, and you may also wish to reduce it and place it on the page for notebook holes or binder margins.

AX is appropriate for small schematics (such as the internals of a single flip-flop), or prints of larger schematics for archive or reference where detail and the ability to pencil in changes is not important.

#### BX SHEET

This size is perfect for print on 13-16 in "wide carriage" printers, or some of the newer laser printers. It may require some slight reduction to fit. On a wide carriage printer, you may obtain blank white "wide" form fanfold paper and print one schematic to a page. They can even be bound into books sold especially for wide form.

BX sheets are good for small to medium schematics, and reduce to AX while remaining readable.

#### CX SHEET

This is my "workhorse" sheet size for IC design. It can be printed at full size by a wide carriage printer. It is large enough to represent major sections of a complex IC, but is still small enough to review at your desk. It does require special paper, however, and consequently requires individual sheet feed (at the speeds such a sheet will be printed at, this is not an serious problem). It is not very readable when reduced to AX.

#### DX SHEET

Requires a plotter or large format electrostatic printer. DX and above are sizes used for tabel drafting and layouts. Although D and E schematics were standard for electronics drafting in the past, this was mainly to draw features using full size logic symbols and then reducing to eliminate pencil marks and small inperfections. Since electronic drafting delivers perfect prints, this is less of a problem today.

#### EX SHEET

Requires a plotter or large format electrostatic printer as for DX. Same coments apply as for D.

Many engineers can and do make their own sheet system from scratch. Often this is done by finding the best print size avalible on the output device you have, and creating a border to match. You can always resize to fit most any paper when it comes time to publish (perhaps with a little blank margin). The borders provided with ICD can be editted easily, or you can create your own, complete with fancy corporate logo and copyright warnings.

### DOT AND LINE GRIDS

The dot and line grids provide reference for the process of laying down schematic elements. The dot grid is used to establish the minimum drawing granularity, whereas the line grid is used to establish orderly ranks of logic on a schematic. Although drawing "off grid" is downright foolhardy, the display of the dot grid and the use of the line grid are personal descisions (although I have noticed that engineers who use them generally create neater looking schematics !).

The dot grid is turned off and on by PB1/DOTS. It acts as a toggle switch, and will turn green when it is on. Whether or not the dot grid is enabled for viewing, all drawing tools will be aligned to the dot grid when SNAP is active.

The dot grid size (or space between dots) can be set by editting the dot grid size field. This operates whether or not the dot grid is actually displayed. It both sets the dot grid that will be displayed, and the grid to which drawn figures are SNAPed to.

Various settings of the dot grid can also be saved and restored with the radio buttons. PB2 and the button will store the current dot spacing setting. PB1 and the button will activate the dot spacing stored there. The button turns green when a dot space value has been stored there.

When changing the dot spacing, it is wise to do so by exactly halfing or doubling the current value. The reason is to garantee that the dots points in one size correspond to the dot points in another size.

It is recommended that you ALLWAYS restore the dot grid to the default size for wiring or placing components ! The reason is that you must garantee that two wires or connectors are truly at the same point for them to be considered connected by ICD.

The line grid is turned off and on by PB1/LINES. It acts as a toggle switch, and will turn green when it is on. When using the borders AX thru EX, the line grid serves a further purpose by lining up with the cross reference indicators in the margins.

Various settings of the line grid can also be saved and restored with the radio buttons. PB2 and the button will store the current line spacing setting. PB1 and the button will activate the line spacing stored there. The button turns green when a line space value has been stored there.

### DRAWING FIGURES

Everything that can be drawn in ICD is made up of a few simple figure types. In fact, ICD actually draws only lines and arcs. It is, however, possible to draw virtually any figure required in schematic drafting using just these figures.

The line mode is selected by PB1/LINE. When selected, the LINE button turns green, and any other figure drawing mode is deactivated. The starting point for the line in the viewport is selected and PB1 or PB2 pressed to begin the line. If the button is held, the line can be dragged, and you move the puck to the end of the line and release the button to complete. Note that you must move the puck a minimum of 10 screen pixels to complete a drag. If you move the puck less than that and release, you will simply be placed in the normal draw mode. If you press and release the button to start, you will move the puck to the end of the line and press PB1 or PB2. PB2 ends the line. PB1 ends the line and automatically starts a new line (usefull for point to point drawing). A line in progress can be cancelled by PB4.

When drawing a line, a blue "line cursor" will be "rubberbanded" after the cursor. The blue line indicates exactly how the line will be drawn when it is completed.

When you are drawing lines and you gain the speed that comes with experience, try to not "walk" each point, or hit buttons and move the puck at the same time. The best way is to move, stop, and shoot. Otherwise you will set off a drag unintentionally, and perhaps hit the wrong start/stop point.

If SNAP is on, each start and end point is placed at the nearest grid point to the cursor location. You will see the line cursor begin at the grid point to indicate this. It is always a good idea to draw to the grid. If you are having trouble getting the line where you want it, half the grid size. This will give you the best quality drawings.

The buttons ANY, 45 and 90 select the "restriction" mode. Activating one of these buttons will turn that button green and deactivate the others. In the 90 mode, lines will be restricted to horizontal or vertical lines. After you have started the line, the endpoint will be the closest point on such a line to the cursor. The line cursor will show you what will be drawn. In 45 mode, lines will be restriced to horizontal, vertical and diagonal lines. In ANY mode, there is no restriction on line direction. Using SNAP off and ANY results in unrestricted free hand drawing.

The bold line mode is activated with PB1/BOLDLINE. This mode works exactly as for normal lines, with one exaception. Bold lines are ALWAYS restricted to 90 regardless of whether or not that button is selected.

The box and bold box modes are selected by PB1/BOX and PB1/BOLDBOX. The box modes will draw any arbitrary rectangle. You start off a box by moving the cursor to a starting point and pressing PB1 or PB2. These may be held to drag the box, and released at the end point, or the puck can be moved to the end point and PB1 or PB2 hit again to end the box. While drawing a box, a blue "box cursor" shows you exactly how the box will be drawn. If SNAP is on, the starting and ending corners of the box will be snapped to the grid. A box drawing in progress can be canceled by PB4.

The circle mode is activated with PB1/CIRCLE. The center point of the circle is selected, and PB1 or PB2 starts the circle. The circle may be dragged to the destination. You then specify a point on the curcumference of the circle, and release the drag or hit PB1 or PB2. A "circle cursor" will show you the exact circle that will be drawn. If SNAP is on, the center of the circle will be restricted to a grid point, and the radius will be restricted to an even span of grids.

The arc mode is activated with PB1/ARC. One endpoint of the arc is selected, and PB1 or PB2 hit. Move the cursor to the other endpoint, and again hit PB1 or PB2, or release the drag. Finally, pick a point on the arc and hit PB1 or PB2. This selects the curcumference of the circular arc. All during the arc draw, a blue "arc cursor" will show you the exact shape of the arc to be drawn. If SNAP is on, the both endpoints of the arc are restricted to grid points. The arc curcumference, however, is never restricted.

### PLACING WIRES AND BUSSES

Placing a wire or bus is executed just as for a line or a bold line. The wire placement mode is activated by PB1/WIRE, and the bus placement mode is activated by PB1/BUS. Wires behave just as lines during placement, and busses behave as bold lines (including being restricted to 90). Wires and busses have special meaning to ICD, however.

Wires and busses have "endpoints" which are potential connections to other wires. Any two wires or busses whose endpoints lie on the same realspace coordinates and at least one of which is "orthogonal" (exactly vertical or exactly horizontal) are automatically connected together by ICD. One of the faults with a schematic package with completely variable viewing scale as ICD does is that two wires or busses can be a single micrometer off and not be connected. Two such wires look connected at ordinary magnifications, but ICD will not consider them to be connected. Because of this, you should ALLWAYS place wires and busses with snap on. Further, the dot grid should be left at the default value of 1.5mm when wiring. If for some special reason you really MUST use a different setting, you must wire the ENTIRE schematic using that grid value, and the libraries provided you with ICD may not be useable.

Two wires or busses which are both orthogonal can also be joined "at midpoint" with the endpoint of one wire resting somewhere on the other wire's midsection.

Where more than two wires or busses join the same point, ICD will automatically place a JUNCTION there, as indicated by a small black dot. One wire joining another at midsection is also considered three wires. Junctions can also be placed manually, although the only purpose of placing such a junction is to connect two orthogonal wires that cross without their endpoints touching.

The junction mode is entered by PB1/JUNCTION. Then a junction is placed by locating the cursor at the junction location and pressing PB1. If SNAP is on, the junction will be placed at the nearest grid point.

The size of junctions, both printed and viewed on the screen, can be adjusted by editting the junction size field. This will change all junctions anywhere in the schematic.

ICD will automatically eliminate redundant wires and busses (wires and busses that overlap), and join "colinear" short ones to make them as large as possible. This effect is mainly noticeable when you delete them.

All of the above applies equally to wires and busses. Wires may be freely joined to other wires, and busses to other busses. But ICD never automatically connects a wire to a bus or bus to wire. A bus and a wire whose endpoints meet, or a wire that meets a bus at midpoint is NOT CONNECTED. No connector is placed.

The majority of wiring work can be done by laying down wires and letting ICD worry about connecting them together. For the vast majority of wiring work, leave 90 and SNAP on, which automatically garantees that your wires are orthogonal and connect. There are a few cases where non 90 wires look better than 90s, for example the s/r ff in fig. x. Here, the outputs must exactly cross. Of course, it can be drawn as in fig. x. Drawing off 90s is ok, but go back to 90 mode after the problem is solved. There is only one thing to say about practices such as diagonal clock entry to a block and other diagonal routing procedures: DON'T. Especially bad are TWO diagonal wires that attempt to connect. They will not do so.

There is a reason for the ICD rules about joining wires. It is vital that ICD and you agree exactly on how a given schematic is wired together. Far better that I receive complaints about wiring restrictions than about hours tracking down "no connects" buryed somewhere in the schematic.

### NETS, WIRES AND BUSSES

Whenever a wire is created, ICD also creates a "node" for it. A node is the electrical abstraction of any number of points joined together by zero resistance. A node might have any number of schematic wires or busses joined to it, but it is only one node and can contain only one voltage value at a time.

Nodes in ICD have two properties: a NAME and an ORDINAL. The name of the node is an 8 character string, while the ordinal is a number. If you just draw a wire, these will be selected automatically for you (and indeed, most nodes can be left unnamed). The ordinal of such a wire is allways 0, and the name is picked of the form "N0000001", where the number imbedded in the string changes from node to node (but in no garanteed order !).

After a wire is placed, its name and ordinal will appear in the name and ordinal value windows. When you join two wires, the name and ordinal that appear are of the node that represents them both.

The name of any wire or bus can be found or set with the NAME function. This is activated with PB1/NAME. You place the cursor as close as possible to the wire, and press PB1 to retreive the name and ordinal of the wire. The name of a wire can be set by PB2 near the wire. The name of the wire will become whatever is in the name and ordinal value buttons. To change a node name to a specific value, you edit the name and ordinal value buttons, then set a wire of the node using the NAME function. ICD allways selects the wire closest to the cursor to operate on, and will not select a wire farther than 10 pixels from the cursor.

When you name a wire or set its ordinal, that node now has "priority" over a ICD named node. When a user named wire is joined to an ICD named wire, the resulting node will be named for the user named wire. When two user named wires are joined, the result is either of the names, picked at random.

Normally there is no need to specifically name a given node or wire. These names are important when a CONNECTor is established for a cell, so that ICD knows how to wire a schematic to its symbol.

Busses have names, just as for wires, but have no ordinals. The NAME function can be used on busses just as for wires, but the ordinal field will be blank, and will be ignored if set.

A bus is actually a collection of any number of nodes. The key to how wires are joined to busses is the ordinal number of the wire's node. When a wire is joined to a bus, the name of both the bus and the wire is set just as when two wires are joined, with the bus being renamed for the wire or the wire named for the bus. The ordinal of the wire is unchanged, however. When two wires are attached to the same bus, and they have the same ordinal, those wires are joined to the same electrical node. When the two wires have different ordinals, they are not of the same node (despite having the same name), and may have entirely different voltage values.

A wire is joined to a bus by placing the endpoint of an orthogonal wire anywhere along a bus (including it's endpoint). The wire is then married to the bus by placing a JUNCTION where the wire's endpoint joins the bus. Placing the endpoint of a bus on a wire IS NOT a legitimate connection.

The reason that ICD does not automatically connect the wire to the bus for you is to allow you to set the ordinal of the wire before you join it to the bus. If you have been drawing the wire, it's name and ordinal will be in the name and ordinal value buttons (or can be loaded via the NAME function). The ordinal and perhaps the name of the wire are changed as desired, and then the JUNCTION joining the wire to the bus is placed.

Once a wire is joined to a bus, it is joined to all other wires of the same ordinal attached to the same bus. Changing the ordinal of the that wire once it is attached will not help; all of the other wires will also have their ordinals changed.

### CONNECTORS

Connectors are specified and placed much as for JUNCTIONs. PB1/CONNECT sets the connector placement mode. PB1 at the cursor location will then place a connector. The size of the connector is set by the connector size value button. This button is editted to change the value, and then the connector size will be set for both printout and viewport.

On the schematic, the location of a connector is not relivant. It simply indicates that the node it is connected to will be connected to a matching connector on the symbol for that sheet. Usually, connectors are brought to the outside of a schematic and labeled clearly. One school of structure says that input connectors should be grouped at the left side of the sheet, and output connectors at the right.

A connector takes the name of the node to which it is attached. The NAME operator works equally well on connectors. If the name of the wire/bus to which a connector is changed, the connector name changes too. Connectors may attach to both busses and wires.

The meaning of a connector is a connect all nodes of a given name to the "external world" outside a schematic. The connection is done according to the node's ordinal. A connector of name "xyz" may connect to the outside node "qrs", but only if they are the same ordinal. When a connector represents a bus, all the wires contained within the bus are connected to wires in the outside world bus according to their ordinals, with matching ordinals connecting.

### TRACING NODES/BUSSES

The TRACE function is entered by PB1/TRACE. Position the cursor as close as possible to the wire, bus, junction or connector to be traced. The nearest such figure will be selected for trace. The firgure must be within 10 screen pixels from the cursor.

The node traced will be changed to one of 6 different colors. All wires, busses, junctions and connectors attached to that node are presented in color. The name, and ordinal as applicable, are also placed into the name and ordinal value buttons. You can trace up to 6 nodes at once, limited only by the number of avalible tracing colors. When you trace more than that, the "oldest" color will be reset to black, and the new node gets that color. The trace may be cleared by PB4, or will be automatically cleared when any other schematic drawing mode is activated.

### THE RULER

The ruler is a general purpose measurement device. The ruler display is automatically invoked whenever there is any distance being marked off on the schematic. This includes the functions PAN, IN, LINE, BOX, BOLDLINE, BOLDBOX, WIRE, and BUS. When PAN is executed, the ruler shows you the distance from the compass rose to the current cursor location (distance the schematic will be moved). The RULER value button indicates the direct length, and the X and Y value buttons indicate the X and Y distances. During the IN function, the ruler measures the demensions of the zoom indicator box. During a LINE, BOLDLINE, WIRE or BUS operation, the ruler measures the length of the line that will be drawn (the cursor line). During the BOX or BOLDBOX operations, the ruler measures the X and Y demensions of the box to be drawn (or cursor box), and somewhat uselessly indicates the box diagonal.

The ruler can also be used to measure any given span on the schematic. Activate the ruler using PB1/RULER. Then place the RULER target using PB1 at the desired start location. The ruler will then measure the direct, X and Y distances from the target to the current cursor location. The target can be moved by PB1 at the new location, any number of times. The ruler mode is exited with PB4 or PB1/RULER again.

### TEXT PLACEMENT

There are two ways to place text onto an ICD schematic. You can simply draw the text onto the schematic, directly or by defining a set of cells, one per character. This is the key to obtaining custom fonts if you require them. Characters can be drawn with either just line segments, or lines and arcs for a smoother look. Use of bold lines will yield bold characters. Since cells cannot be scaled under ICD, you must make a character set for each scale as required. You will find it helpfull to set the dot grid at an extra fine resolution to create a character set. An example of such a custom character set comes with ICD.

ICD provides a much more convenient method of entering text, however, using characters that may be scaled to any given size. The TEXT mode is activated by PB1/TEXT. The lower left hand corner of the desired text location is found with the cursor, then PB1 places the "text cursor". The text cursor is a blue box that indicates the placement of the character to be drawn. The text cursor can be moved any number of times by pressing PB1 again. To enter text at the cursor location, the characters are typed on the standard keyboard. They will appear at the cursor location as typed, and the text cursor will move right. If the SNAP mode is on, the lower left hand corner of placed text will be placed on grid.

To back up (erase the last character), hit the BACKARROW key on the keyboard. The character to the left of the text cursor will be erased, and the text cursor will back up one character. The characters typed on the screen are entered when the ENTER key is pressed on the keyboard. Each line of characters so entered is considered a unit by ICD. This is important for character deletes and rotations. The text entry mode is stopped by PB4.

The size of entered text appears in the text size value field. This size is the size of each character across its base. The distance between each character (horizontally) is found by half the character size (note that a space character is as large as a normal character). The size field can be editted, and characters at the new size placed.

Because it is common to need several different sizes of text, you may store and select text sizes from the radio buttons. The current text size is placed in a button by PB2 and the button, A thru H. The button will turn green to show that it is not empty. The text size in a button is activated by PB1 and the button.

Text orientation can be selected from either 0 degrees (left to right drawing), and 90 degree drawing (top to bottom placement). At 90 degrees, text entry works exactly as at 0 if you were to look at the viewport sideways. Everthing is turned 90 degrees clockwise.

The 0 or 90 degree modes are selected by PB1/0 or PB1/90.

### DELETIONS AND RIPS

The delete mode is activated by PB1/DELETE. Any drawn object can be deleted by placing the cursor as close as possible to the object and pressing PB1. The cursor must be within 10 screen pixels of the object. If more than one object is within range, the closest object will be deleted. If neither is closer than the other (such as when the cursor is on the objects, and the objects are overlaid), either object may be deleted. There is no way to predict which. With two exceptions, the distance to an object is the distance from the cursor to the black lines representing a figure. The exceptions are character strings, and cells. Each of these behaves as if it were a solid rectangle. If the cursor is inside the cell or text "bounds", the cursor is considered to be "on" the object (even if it is white space).

Delete operates on each object individually. For example, if you had placed two wires as in fig. xx. When you placed the wires, the junction between then would be placed automatically. But deleting both wires would still leave the junction, and you must delete that too. ICD does not delete the junction automatically.

The RIP operator is used to intellegently delete networks. RIP removes all the connections of a node, including WIRES, BUSes, JUNCTIONS and CONNECTors. The RIP mode is entered with PB1/RIP. You then position the cursor next to the object to rip, which must be within 10 screen pixels. The nearest object is selected for RIP. When an object is ripped, all of the items connected in that node are deleted.

### SAVES, CUTS AND PASTES

ICD can manipulate arbitrary sized rectangular regions on a schematic. You may save any region, place any number of copies of that onto the schematic, transfer it to another schematic, store it for future reference, and delete any region.

The SAVE mode is entered by PB1/SAVE. The starting point ot the save region is placed by PB1 at the proper cursor location. The cursor is then moved to the opposite diagonal of the save rectangle. A blue box cursor will be rubberbanded to show the extent of the save box. The end of the box is marked by another PB1, at which time the blue cursor box will disappear, and the region has been saved. The exact placement of the save box is important. Even if the save region contains empty space, the region that the saved block occupies will be as you have specified. To be saved, an object must be entirely within the save region or one of LINE, BOLDLINE, BOX, BOLDBOX, WIRE or BUS. These last figures may have the sections within the save region stored without the rest of the figure outside the region. In the case of CIRCLes, ARCs, and JUNCTIONs, whether or not the figure is WITHIN the save region is determined by an imaginary box drawn around the figure (much as in the bounding box for the schematic). If SNAP is on, the save box cursor will be aligned to the dot grid (and the save will be in even grid units).

The CUT mode is specified by PB1/CUT. The region is selected just as in the SAVE operation, and the region is saved as well. The difference is that all figures in the CUT region are deleted. If the entire figure is contained in cut region, it is simply deleted. If it is part way in and part way out, and one of LINE, BOLDLINE, BOX, BOLDBOX, WIRE, or BUS, it will be cut into separate peices, with the part inside the cut disappearing. Since a BOX or BOLDBOX cannot exist as a box so broken, ICD automatically converts them to a set of LINEs or BOLDLINEs.

Both the SAVE and the CUT function store the block specified as the "current" block, which stays active until replaced by another block. It will even stay if you change schematics, which allows you to move blocks to a different sheet.

The current block is replaced on a sheet by the PASTE function. This is activated by PB1/PASTE. After you do so, and move the cursor to the viewport, you will se a blue box that follows the cursor. The cursor is pinned to the upper left hand corner of the box. This box indicates the bounds of the original saved region that is active for paste. The region is pasted by PB1. The save region will be placed at the current cursor location. If SNAP is on, the upper left placement point will be limited to the grid.

When wires or bussses are PASTEd, they behave exactly as if each wire or bus was placed individually, including automatic connection and placement of junctions. When SAVE/CUT and PASTE operations are being done on wires or busses, SNAP should be on, and the dot grid should be at the default (just as when using WIRE or BUS).

The name and ordinal of wires and busses behave specially for the case of block operations. The "priority" at which newly placed names replace old ones expands, as follows:

1. *(highest priority)* Existing, user defined names on the schematic.
2. User defined names in the placed block.
3. Temp names (in either the schematic or the placed block).

To save and restore more than one block, a set of radio buttons is provided, A thru H. The current save block is saved in a button by PB2 and the button. The button will turn green to indicate that the button is not empty. The current save block will be unchanged. The contents of a button can be restored to current by PB1 and the button.

## THE SYMBOL EDITTOR

The SYMBOL mode is activated by PB1/SYMBOL. The SYMBOL mode is an analog to the SCHEMAT mode. All the controls work exactly the same as in the SCHEMAT mode. It is defined as a separate mode to accentuate that it WILL NOT generate electrical wiring. The WIRE, BUS, JUNTION, and CONNECT figures can be drawn on a symbol sheet, but serve as comments only. The SYMBOL mode exists simply to draw ICONS to represent schematics.

The symbol sheet exists as a sheet in the current cell just as the schematic sheet does. While a cell is selected (current), you may swap back and forth between the schematic and cell sheets with the SCHEMAT and SYMBOL buttons. The symbol sheet is treated differently than the schematic sheet. Whereas the schematic sheet has a border and is a complete drawing, the symbol sheet generally just contains a small peice or icon to be placed as part of a larger drawing. That icon is usually a "part icon", or a representation of an electrical module (including connections). Alternately, it may be a peice of a larger drawing. For instance, you might define your company logo in a symbol, intending to place it into various schematics.

To draw a typical icon, you may wish first of all to "half" the grid to draw finer symbology. You must be sure, however, that all connectors in the symbol end up on the original grid when the bounding box is found. The way to do this is to make sure that the bounding box is on the original grid. To verify this, reset the grid to the default, then check that the outermost parts of the figure are on grid.

As in the schematic sheet, the connectors generated by CONNECT have special meaning. They connect to the node of the same name on the schematic sheet, which must have a matching connector. Connectors can be given a name all by themselves if required.

Connectors are also special in that they are "invisible" when the icon is placed onto another sheet (and they will not therefore enter into the bounding box calculation at that time). Connectors only serve as placeholders in the symbol, to indicate where connections to the schematic will occur.

## CELLS AND CELL PLACEMENT

ICD is a hierachal schematic system. Each schematic is a collection of cells connected by wires and busses. The heyarchy terminates only at the ICD built - in primitives, such as transistors, resistors and capacitors. Standard PCB schematic edittors stop at cells or parts that are still quite far up in the herarcy, and indeed, may not be able to represent a heyarchy at all. ICs have a far deeper heyarchy. To represent a master/slave latch, for example, we could have the following levels:

1. Master/slave latch.
2. Flow through latch.
3. "and" gate.
4. PMOS and NMOS transistors.

And that is just one small part !

Any cell can be placed "symbolically" within another cell's sheet. In fact, the schematic sheet for a cell can be placed within the same cell's symbol sheet, or the symbol sheet in the schematic sheet. What you may NOT do is place a cell's symbol or schematic sheet in that same sheet. ICD will simply not place such a cell. You may also not place a symbol in a schematic sheet such that the schematic contains itself electrically. This will be an error in the ERC function, and will prevent proper processing of the circuit.

A cell placed onto another sheet can be either as a "comment" or figure without electrical significance, or may represent the symbolic connection of the schematic for that cell into the schematic where placed. Connection occurs ONLY when a cell in symbol mode is placed onto a schematic sheet. Symbol cells placed onto symbol sheets, or schematic cells placed anywhere, are only comments to ICD.

### SELECTING THE CELL TO PLACE

Cells can be selected for placement from three different sources:

1. Cells built - in to ICD.
2. Cells in the current file.
3. Cells in another (external) file.

The cells built - in to ICD are set active by:

| Button | Cell |
|--------|------|
| PB1/NMOS | NMOS transistor. |
| PB1/PMOS | PMOS transistor. |
| PB1/RES | Resistor. |
| PB1/CAP | Capacitor. |
| BP1/DIODE | Vdd (positive power supply connection). |
| PB1/VSS | Vss (negative power supply connection). |

*(This built-in-cell table is misaligned in the recovered stream: a button label and its description were dropped, so `BP1/DIODE` — itself a typo for `PB1/DIODE` — ends up paired with the Vdd description. The original almost certainly had separate `PB1/DIODE` (Diode) and `PB1/VDD` (Vdd) rows.)*

The button activated will turn green, and all other cell buttons will deactivated.

The cells in the current file may be activated several ways. The current cell is displayed in the cell value button. The name of the cell may be simply editted into the cell value button. The cell name must be of a cell that exists in the current file. If not, the cell name will not be accepted. When a cell name is already in the placement button, and a new one is selected, ICD automatically saves the current cell in a "stack". Each "old" cell saved is moved down into the stack, and the other cells in the stack moved down also. These are kept for you by ICD because you must often place similar cells repetitivly on a sheet. An old cell can be brought back to the placement cell button by PB1 and the button. If a new cell selected is the same as an old one already in the stack, it will simply be moved back to the placement button. If a new cell is selected an the stack is already full, the cell on the bottom of the stack will be lost.

The current placement cell can also be selected from the cell directory. Press PB1/CELLS. The viewport will be replaced by a directory of cells in the current file. The cursor may select these cells, and PB2 and the cell name will cause that cell to be placed in the placement cell value button, and set active for placement.

Cells can also be selected for placement from an external file. When such a cell is selected for placement, the cell is copied from the external file into the present file, and will appear in the cell directory. The process of placing a cell into the current file is done by "merge". A cell may contain a symbol sheet, a schematic sheet and other information, or these may be null (a symbol or schematic sheet is also considered null if it is blank). A cell can also reference any number of subcells. When an external cell is copied for a merge, ALL of the cell data, and ALL cells referenced by that cell (and referenced by them, etc., in tree fashion) are loaded to the current file. If there are allready cells with identical names in the current file, those cells will replace the incoming cells. If the duplicate cells in the current file have null data, that data is replaced by the external data as possible. Thus, for example, if the cell "gate" has the symbol sheet defined in the current file, and the external cell has both a symbol and a schematic sheet, the resulting cell will have the current cell's symbol and the external file's schematic sheet. Once a cell is included from an external file, the cell may be editted, without effect to the external file. The current file copy is a true private copy.

Files that are used for this purpose can be called "library" files, and most often are simply collections of placement cells. Several such libraries are provided with ICD. Libraries are a convenient way to place standard cells and standard logic. Otherwise, however, there is no difference between a normal .icd type file and a library file. The external placement function can be used equally well to construct a new design from old files.

Files used as libraries are entered in a stack the same as the cell placement stack. The top button is the file value button. The name of the external .icd file can be directly entered here. New files will replace old files, and those pushed down on the stack, just as for placement cells. Files can also be selected from the files directory. The files directory is activated by PB1/FILES. The viewport will be replaced by a directory of filenames that are in the current directory. These files may be selected with the cursor. PB2 and the file button will place that file into the library file value button in the stack, etc.

The cells in a library file can be examined by hitting PB1 and the file stack button. The viewport will be replaced by a directory of the cells in that file. Two actions are then possible. PB1 and the filename will copy the external cell into the current file, and then set the cell for viewing. PB2 and the filename will copy the external cell into the current file, and place it atop the cell placement stack. Either way, the cell is "accepted" when eitehr of these two operations is done. Because inclusion of a cell may cause any number of subcells to be included in the current file, it is recommended that you carefully examine a perspective cell by loading and examining that library if you do not understand its contents.

### PLACEMENT OF A CELL

Once selected, a cell may be placed upon the current sheet. You may place either the symbol or the schematic sheet of the placement cell. The symbol sheet is activated for placement by PB1/PUTSYMBL, and the schematic sheet by PB1/PUTSCHEM. The button will turn green to indicate that the placement is active. When the cursor is moved into the viewport, you will see a blue box that indicates where the cell will be placed. The cursor holds the upper left hand corner of the cell. The cell is placed by PB1 when the cursor box is located at the desired placement point. The cell will then appear in place of the box. If SNAP is on, the cell placement will be limited to the dot grid. When placing symbols that contain connectors, and are to be used as parts in a circuit, SNAP should be on, and the dot grid set for the standard default. This, and care having been taken to place the connectors on the symbol sheet on grid, will insure that valid circuit connections are made.

Cells can also be rotated or mirrored when they are placed. This allows a single symbol to be used in several different orientations. The cell can be rotated clockwise 0, 90, 180, and 270 degrees. These modes are activated by PB1/0, PB1/90, PB1/180 and PB1/270. The activated mode will turn green. Placement cells can also be mirrored. The mirror mode is activated by PB1/MIRROR. This is a toggle, so that pressing it again will also turn it off. The button turns green to indicate it is active. Mirroring a cell flips it from left to right. A cell can be both rotated and mirrored. In this case, it will be mirrored first, then that mirrored version rotated. Any text in a placed cell is treated specially when rotated. ICD allways keeps such rotated text readable even when rotated. The text will allways read left to right, and is only allowed to be rotated from vertical to horizontal and vice versa. However it appears, the space occupied by the text is the same as it occupied in the original drawing. ICD will "flip" strings left to right, or up to down, to keep it in readable order, but it will still be contained in the same "bounding box" as the original string. In most cases, this creates symbols that can be rotated or mirrored in any fashion without eliminating its readability.

## PRINTING SHEETS

The current sheet in display (either symbol of schematic) can be printed by PB1/PRINT. The sheet will be sent to the printer with the current defaults. The print can be rotated or mirrored with the 0, 90, 180, 270, and MIRROR buttons. These should be set up before the PRINT is executed.

The parameters for a print can be examined/changed by calling up the print parameter menu. Hit PB2/PRINT, and this menu appears. The MAX X and Y are edittable value buttons. They set the size limits on the print swath. Normally, they will be set for the installed print/plot device (at the maximum that the device will provide). If you set the demensions LOWER than the maximum possible, you will get a smaller print than normal. The print will allways be scaled to fit the size of the printout, regardless of the measured size of the sheet. You will get a 1:1 match (where the measurements in edit match the measurements on the printed sheet) when the print demensions match the sheet demensions. The OFFSET X and Y buttons set the left and top margins on the printed page. These are used along with the MAX X and Y buttons to set both the size and location of the sheet on the printed page.

The SHEET X and Y indicate the demensioned size of the sheet, and is equal to the bounding box of the sheet in edit. The PRINT X and Y buttons indicate the actual size of the printed image on the printed sheet. This is equal to the MAX parameters minus the OFFSET parameters. Compare the SHEET and PRINT sizes to see how the print will be scaled. If they are equal, the sheet is 1:1, etc.
