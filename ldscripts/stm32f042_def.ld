
/* Memory Spaces Definitions for STM32F050F4 */

ENTRY(Reset_Handler)

MEMORY
{
  FLASH (rx) : ORIGIN = 0x08000000, LENGTH = 32K
  RAM  (xrw) : ORIGIN = 0x20000000, LENGTH = 6K
}

/* highest address of the user mode stack (6k) */
_estack = 0x20001800;

/* include the sections management sub-script for FLASH mode */
INCLUDE "sections_flash.ld"

