module board.virt.dev;

import syscon = dev.syscon;

alias SysCon = syscon.SysCon!(cast(uint*) 0x100000);
