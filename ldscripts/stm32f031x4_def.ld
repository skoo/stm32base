
/* Memory Spaces Definitions for STM32F050F4 */

ENTRY(Reset_Handler)

MEMORY
{
  FLASH (rx) : ORIGIN = 0x08000000, LENGTH = 16K
  RAM  (xrw) : ORIGIN = 0x20000000, LENGTH = 4K
}

/* highest address of the user mode stack (4k) */
_estack = 0x20001000;

/* include the sections management sub-script for FLASH mode */
INCLUDE "sections_flash.ld"

