# Fandoc v2.0.6
---

[![Written in: Fantom](http://img.shields.io/badge/written%20in-Fantom-lightgray.svg)](https://fantom-lang.org/)
[![pod: v2.0.6](http://img.shields.io/badge/pod-v2.0.6-yellow.svg)](http://eggbox.fantomfactory.org/pods/afFandoc)
[![Licence: ISC](http://img.shields.io/badge/licence-ISC-blue.svg)](https://choosealicense.com/licenses/isc/)

## Overview

*Fandoc is a support library that aids Fantom-Factory in the development of other libraries, frameworks and applications. Though you are welcome to use it, you may find features are missing and the documentation incomplete.*

Alternative and extensible Fandoc writers that provide intelligent context.

`<pre>` blocks are parsed, providing syntax highlighting for code, and table rendering.

Hooks are provided to resolve link and image URLs so invalid links may be highlighted.

## <a name="Install"></a>Install

Install `Fandoc` with the Fantom Pod Manager ( [FPM](http://eggbox.fantomfactory.org/pods/afFpm) ):

    C:\> fpm install afFandoc

Or install `Fandoc` with [fanr](https://fantom.org/doc/docFanr/Tool.html#install):

    C:\> fanr install -r http://eggbox.fantomfactory.org/fanr/ afFandoc

To use in a [Fantom](https://fantom-lang.org/) project, add a dependency to `build.fan`:

    depends = ["sys 1.0", ..., "afFandoc 2.0"]

## <a name="documentation"></a>Documentation

Full API & fandocs are available on the [Eggbox](http://eggbox.fantomfactory.org/pods/afFandoc/) - the Fantom Pod Repository.

## Quick Start

    using afFandoc::HtmlDocWriter
    
    class Example {
        Void main() {
            fandoc := "..."
    
            html := HtmlDocWriter.fullyLoaded.parseAndWriteToStr(fandoc)
    
            echo(html)  // --> <html> ... </html>
        }
    }
    

## Syntax Hightlighting

Preformatted text may have syntax highlighting applied (courtesy of the core [syntax](https://fantom.org/doc/syntax/index.html) pod). Simply prefix the `pre` text with:

    syntax: XXXX

Where `XXXX` is the name of the syntax to use. Example:

    pre>
    syntax: fantom
    
    class Example {
       Void main() {
           echo("Hello Mum!")
       }
    }
    <pre

Common syntaxes include:

* `csharp`
* `css`
* `fantom`
* `html`
* `java`
* `javascript`
* `xml`


For a full list of default supported styles, look in the Fantom installation at the files under `%FAN_HOME%\etc\syntax\`

## Table Rendering

To render a HTML table, use preformatted text with `table:` as the first line.

Table parsing is simple, but expressive. The first line to start with a `-` character defines where the column boundaries are. All lines before are table headers, all lines after are table data.

Example:

    pre>
    table:
    
    Full Name    First Name  Last Name
    -----------  ----------  ---------
    John Smith   John        Smith
    Fred Bloggs  Fred        Bloggs
    Steve Eynon  Steve       Eynon
    <pre

Becomes:

    table:
    
    Full Name    First Name  Last Name
    -----------  ----------  ---------
    John Smith   John        Smith
    Fred Bloggs  Fred        Bloggs
    Steve Eynon  Steve       Eynon
    

Note that any lines consisting entirely of `-` or `+` characters are ignored. This means the above table could also be written as:

    pre>
    table:
    +-------------+-------+--------+
    |             | First | Last   |
    | Full Name   | Name  | Name   |
     -------------+-------+--------+
    | John Smith  | John  | Smith  |
    | Steve Eynon | Steve | Eynon  |
    | Fred Bloggs | Fred  | Bloggs |
    +-------------+-------+--------+
    <pre

## Link Resolving

Link resovlers are used by [HtmlDocWriter](http://eggbox.fantomfactory.org/pods/afFandoc/api/HtmlDocWriter) to transform relative URLs and schemes (of your own design) into fully working absolute URLs. If any given link is not resolved then it is written with an `invalidLink` CSS class, which you should then style as red, or some other appropiate colour.

Some pass-through link resolvers are provided that simply return the given URL, this prevents common links from being rendered as invalid.

Link resolvers let you design your own custom link formats, just like wot Fantom did with fandoc links!

