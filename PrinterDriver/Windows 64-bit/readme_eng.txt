                                                                      Nov. 2021
===============================================================================
About RISO Printer Driver
===============================================================================
                                                        RISO KAGAKU CORPORATION

             ----------------------------------------
                Read before using the product.
             ----------------------------------------

[Contents]
 Notes on use
 Restrictions from software to be used
 Trademarks
 Copyright

===============================================================================
 Notes on use
===============================================================================
(1) Be sure to use the printer driver, which corresponds to your printer's name.

(2) The maximum number of printed copies that can be set for the printer is 
    9,999.
    Although a larger number may be set depending on the application, 
    be sure to set the number of copies to a maximum of 9,999 or less. 
    If a number more than or equal to 10,000 is set, 
    the actual number of printed copies may not be correct.

(3) If you perform multi-page printing from a computer with small available
    space on its hard disk, the spool area of the computer may become
    insufficient and printing may not be performed properly. 

(4) If multi-page printing is not available because of insufficient space
    on the internal HDD, set the protocol for the printing port to [RAW] and
    the ejection mode to [Non-collate].
    Although the number of copies is limited to [1],
    printing can be performed without limiting the number of pages.

(5) If the protocol for the printing port is set to [LPR] or [IPP], the maximum
    file size for printing is 2 GB. 
    For printing a spool file that exceeds 2 GB, set the protocol for the
    printing port to [RAW].

(6) The version and color printing contents output by test printing are the 
    contents displayed by the Microsoft(R) Windows(R) system.
    For the printer driver version, refer to the [Version] button on the
    [Advanced] tab in the [Printing Preferences] dialog. 

(7) If printing does not function properly after installation of the printer 
    driver, restart the print spooler or the OS.

(8) The following character strings may not be displayed completely if they are
    too long.
    - [Destination] field on the [Basic] tab
    - [Name] field on the [Favorites] tab
    - [Font] menu in the [Edit Watermark] screen on the [Layout] tab
    - [Input Text] field in the [Edit Watermark] screen on the [Layout] tab
    - [Font] menu in the [Stamp] screen on the [Layout] tab
    - [Barcode Area Definition] menu on the [Image] tab
    - [Job Name] menu on the [Advanced] tab
    - [Job Comment] menu on the [Advanced] tab
    - [Name] box in the [Custom paper entry] screen on the [Environment] tab
      of the Property dialog box

(9)  This product is designed for "Desktop Style", and does not work on
     "Windows Store App".

(10) When using this product as a Shared Printer, be sure to restart the client
     PC before printing if you update the printer driver on the client PC
     with [Update Driver]. Otherwise, the printer driver may not work properly.
     If you perform printing before restarting the PC, delete the printer driver
     and reinstall it.

(11) The Quick Installer may not run on a server on your network.
     Please run the Quick Installer on your local PC.


===============================================================================
 Restrictions from software to be used
===============================================================================
(1) Be sure to remove the check mark from [Collate] in the print dialog 
    application. Remove it even for collated printing.
    If the checkmark is placed, printing may not be performed correctly. 

(2) When printing files from Microsoft Excel(R) with Print what set to 
    [Entire workbook], 
    if [Page Setup] or [Print Setting] varies with the sheet, 
    printing may not be performed correctly. 
    In this case, set [Page Setup] and [Print Setting] the same for all sheets.

(3) In Microsoft Word, the paper size displayed on the application and the
    paper size displayed in the printer driver may not match.
    The paper size set on the application is output.

(4) To print data of a mixed size original from Adobe(R) Reader(R), set the 
    application as follows:
     * Page Scaling: Fit to Printable Area
     * Auto-Rotate and Center: Select 
     * Choose paper source by PDF page size: Select 
    Note that part of an image may be missing if using Adobe Reader 10.0.0. 

(5) When printing files from Adobe Acrobat(R) or Adobe Reader, if
    [Line smoothing] is set to [OFF] or [Low], some characters may be printed
    thinner than others. 
    In this case, set [Line smoothing] to [High].
    
(6) If data of a mixed size original is printed with "Mixed Size Original"
    set to "ON" and "Fold" set to "Z-fold" using Adobe Acrobat 8 or
    Adobe Reader 8, the application automatically rotates the data,
    thus, the print result is rotated by 180 degrees.

(7) In Adobe(R) Illustrator(R) for Windows, 
    the settings made in [Printer(U)] of the [Print] dialog may not be reflected
    in the [Print] dialog at first time. (For example, the values of 
    [Width] and [Height] set in [Custom] of [Original size])
    In this case, click [Printer(U)] again, and then click [Print] in the 
    [Print] dialog that appears, and the settings may be reflected.

(8) If data including an object with transparent setting for filling color is 
    printed, the data may not be printed in the correct color.


===============================================================================
 Trademark
===============================================================================
Microsoft, Windows and Excel are either registered trademarks or trademarks of
Microsoft Corporation in the United States and/or other countries.

Adobe, Acrobat and Reader are either registered trademarks or trademarks of
Adobe in the United States and/or other countries.

Other corporate names and/or trademarks are either registered trademarks or
trademarks of each company, respectively.

===============================================================================
 Copyright
===============================================================================
Reproduction or copying of this instruction or any parts there of without
permission is strictly prohibited.

-------------------------------------------------------------------------------
Although every effort has been made to ensure that the contents of this
instruction are error-free, please contact us if you notice any errors or
other points which should be brought to the company's attention.

(C)Copyright 2021 RISO KAGAKU CORPORATION, JAPAN


ORPHIS_FW_Readme_EN-02