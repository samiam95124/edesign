{******************************************************************************
*                                                                             *
*                        ICD USER INTERFACE MODULE                            *
*                                                                             *
* Pascaline port of the ICD graphics/windowing layer. This module replaces    *
* the direct-to-hardware display stack of the original (pixel.asm,           *
* drawa/drawb.asm, the card drivers and the bitmap font) with the Pascaline   *
* graphics library, and carries the ported viewport, rubber-band, button     *
* and window-management layers from icdb.pas, icda.pas and icdc.pas.         *
*                                                                             *
* The base layer below is the only place that calls the graphics library     *
* directly. Everything above it is ported ICD code.                          *
*                                                                             *
******************************************************************************}

module icdui(output);

joins graphics;

uses icddef;
