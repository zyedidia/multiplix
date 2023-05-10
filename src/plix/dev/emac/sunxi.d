module plix.dev.emac.sunxi;

import core.volatile : vst, vld;

import plix.timer : Timer;

struct EmacRegs {
    uint ctl;         // 0x00
    uint tx_mode;     // 0x04
    uint tx_flow;     // 0x08
    uint tx_ctl0;     // 0x0c
    uint tx_ctl1;     // 0x10
    uint tx_ins;      // 0x14
    uint tx_pl0;      // 0x18
    uint tx_pl1;      // 0x1c
    uint tx_sta;      // 0x20
    uint tx_io_data;  // 0x24
    uint tx_io_data1; // 0x28
    uint tx_tsvl0;    // 0x2c
    uint tx_tsvh0;    // 0x30
    uint tx_tsvl1;    // 0x34
    uint tx_tsvh1;    // 0x38
    uint rx_ctl;      // 0x3c
    uint rx_hash0;    // 0x40
    uint rx_hash1;    // 0x44
    uint rx_sta;      // 0x48
    uint rx_io_data;  // 0x4c
    uint rx_fbc;      // 0x50
    uint int_ctl;     // 0x54
    uint int_sta;     // 0x58
    uint mac_ctl0;    // 0x5c
    uint mac_ctl1;    // 0x60
    uint mac_ipgt;    // 0x64
    uint mac_ipgr;    // 0x68
    uint mac_clrt;    // 0x6c
    uint mac_maxf;    // 0x70
    uint mac_supp;    // 0x74
    uint mac_test;    // 0x78
    uint mac_mcfg;    // 0x7c
    uint mac_mcmd;    // 0x80
    uint mac_madr;    // 0x84
    uint mac_mwtd;    // 0x88
    uint mac_mrdd;    // 0x8c
    uint mac_mind;    // 0x90
    uint mac_ssrr;    // 0x94
    uint mac_a0;      // 0x98
    uint mac_a1;      // 0x9c
}

struct SramcRegs {
    uint ctrl0;
    uint ctrl1;
}

struct EmacEthDev {
}

enum Cfg {
    /* 0: Disable       1: Aborted frame enable(default) */
    EMAC_TX_AB_M =		(0x1 << 0),
    /* 0: CPU           1: DMA(default) */
    EMAC_TX_TM =		(0x1 << 1),

    EMAC_TX_SETUP =		(0),

    /* 0: DRQ asserted  1: DRQ automatically(default) */
    EMAC_RX_DRQ_MODE =	(0x1 << 1),
    /* 0: CPU           1: DMA(default) */
    EMAC_RX_TM =		(0x1 << 2),
    /* 0: Normal(default)        1: Pass all Frames */
    EMAC_RX_PA =		(0x1 << 4),
    /* 0: Normal(default)        1: Pass Control Frames */
    EMAC_RX_PCF =		(0x1 << 5),
    /* 0: Normal(default)        1: Pass Frames with CRC Error */
    EMAC_RX_PCRCE =		(0x1 << 6),
    /* 0: Normal(default)        1: Pass Frames with Length Error */
    EMAC_RX_PLE =		(0x1 << 7),
    /* 0: Normal                 1: Pass Frames length out of range(default) */
    EMAC_RX_POR =		(0x1 << 8),
    /* 0: Not accept             1: Accept unicast Packets(default) */
    EMAC_RX_UCAD =		(0x1 << 16),
    /* 0: Normal(default)        1: DA Filtering */
    EMAC_RX_DAF =		(0x1 << 17),
    /* 0: Not accept             1: Accept multicast Packets(default) */
    EMAC_RX_MCO =		(0x1 << 20),
    /* 0: Disable(default)       1: Enable Hash filter */
    EMAC_RX_MHF =		(0x1 << 21),
    /* 0: Not accept             1: Accept Broadcast Packets(default) */
    EMAC_RX_BCO =		(0x1 << 22),
    /* 0: Disable(default)       1: Enable SA Filtering */
    EMAC_RX_SAF =		(0x1 << 24),
    /* 0: Normal(default)        1: Inverse Filtering */
    EMAC_RX_SAIF =		(0x1 << 25),

    EMAC_RX_SETUP =	(Cfg.EMAC_RX_POR | Cfg.EMAC_RX_UCAD | Cfg.EMAC_RX_DAF | Cfg.EMAC_RX_MCO | Cfg.EMAC_RX_BCO),

    /* 0: Disable                1: Enable Receive Flow Control(default) */
    EMAC_MAC_CTL0_RFC =	(0x1 << 2),
    /* 0: Disable                1: Enable Transmit Flow Control(default) */
    EMAC_MAC_CTL0_TFC =	(0x1 << 3),

    EMAC_MAC_CTL0_SETUP =	(EMAC_MAC_CTL0_RFC | EMAC_MAC_CTL0_TFC),

    /* 0: Disable                1: Enable MAC Frame Length Checking(default) */
    EMAC_MAC_CTL1_FLC =	(0x1 << 1),
    /* 0: Disable(default)       1: Enable Huge Frame */
    EMAC_MAC_CTL1_HF =	(0x1 << 2),
    /* 0: Disable(default)       1: Enable MAC Delayed CRC */
    EMAC_MAC_CTL1_DCRC =	(0x1 << 3),
    /* 0: Disable                1: Enable MAC CRC(default) */
    EMAC_MAC_CTL1_CRC =	(0x1 << 4),
    /* 0: Disable                1: Enable MAC PAD Short frames(default) */
    EMAC_MAC_CTL1_PC =	(0x1 << 5),
    /* 0: Disable(default)       1: Enable MAC PAD Short frames and append CRC */
    EMAC_MAC_CTL1_VC =	(0x1 << 6),
    /* 0: Disable(default)       1: Enable MAC auto detect Short frames */
    EMAC_MAC_CTL1_ADP =	(0x1 << 7),
    /* 0: Disable(default)       1: Enable */
    EMAC_MAC_CTL1_PRE =	(0x1 << 8),
    /* 0: Disable(default)       1: Enable */
    EMAC_MAC_CTL1_LPE =	(0x1 << 9),
    /* 0: Disable(default)       1: Enable no back off */
    EMAC_MAC_CTL1_NB =	(0x1 << 12),
    /* 0: Disable(default)       1: Enable */
    EMAC_MAC_CTL1_BNB =	(0x1 << 13),
    /* 0: Disable(default)       1: Enable */
    EMAC_MAC_CTL1_ED =	(0x1 << 14),

    EMAC_MAC_CTL1_SETUP =	(Cfg.EMAC_MAC_CTL1_FLC | Cfg.EMAC_MAC_CTL1_CRC | Cfg.EMAC_MAC_CTL1_PC),

    EMAC_MAC_IPGT =		0x15,

    EMAC_MAC_NBTB_IPG1 =	0xc,
    EMAC_MAC_NBTB_IPG2 =	0x12,

    EMAC_MAC_CW =		0x37,
    EMAC_MAC_RM =		0xf,

    EMAC_MAC_MFL =		0x0600,

    /* Receive status */
    EMAC_CRCERR =		(0x1 << 4),
    EMAC_LENERR =		(0x3 << 5),

    EMAC_RX_BUFSIZE =		2000,
}

private void emac_inblk_32bit(uint* reg, uint* data, int count) {
    int cnt = (count + 3) >> 2;

    if (cnt) {
        uint* buf = data;

        do {
            uint x = vld(reg);
            *buf++ = x;
        } while (--cnt);
    }
}

private void emac_outblk_32bit(uint* reg, uint* data, int count) {
    int cnt = (count + 3) >> 2;

    if (cnt) {
        uint* buf = data;

        do {
            vst(reg, *buf++);
        } while (--cnt);
    }
}

private int emac_mdio_read(EmacRegs* regs, int addr, int devad, int reg) {
    // issue the phy address and reg
    vst(&regs.mac_madr, addr << 8 | reg);
    // pull up the phy io line
    vst(&regs.mac_mcmd, 0x1);
    // wait read complete
    Timer.delay_ms(1);
    // push down the phy io line
    vst(&regs.mac_mcmd, 0x0);
    // read data
    return vld(&regs.mac_mrdd);
}

private int emac_mdio_write(EmacRegs* regs, int addr, int devad, int reg, ushort value) {
    // issue the phy address and reg
    vst(&regs.mac_madr, addr << 8 | reg);
    // pull up the phy io line
    vst(&regs.mac_mcmd, 0x1);
    // wait write complete
    Timer.delay_ms(1);
    // push down the phy io line
    vst(&regs.mac_mcmd, 0x0);
    // write data
    vst(&regs.mac_mwtd, value);
    return 0;
}

private void emac_setup(EmacRegs* regs) {
    // Set up TX
    vst(&regs.tx_mode, Cfg.EMAC_TX_SETUP);

	// Set up RX
    vst(&regs.rx_ctl, Cfg.EMAC_RX_SETUP);

	// Set MAC
	// Set MAC CTL0
    vst(&regs.mac_ctl0, Cfg.EMAC_MAC_CTL0_SETUP);

	// Set MAC CTL1
	uint reg_val = 0;
    // TODO: full duplex
	// if (priv.phydev.duplex == DUPLEX_FULL)
	// 	reg_val = (0x1 << 0);
    vst(&regs.mac_ctl1, Cfg.EMAC_MAC_CTL1_SETUP | reg_val);

	// Set up IPGT
    vst(&regs.mac_ipgt, Cfg.EMAC_MAC_IPGT);

	// Set up IPGR
    vst(&regs.mac_ipgr, Cfg.EMAC_MAC_NBTB_IPG2 | (Cfg.EMAC_MAC_NBTB_IPG1 << 8));

	// Set up Collison window
    vst(&regs.mac_clrt, Cfg.EMAC_MAC_RM | (Cfg.EMAC_MAC_CW << 8));

	// Set up Max Frame Length
    vst(&regs.mac_maxf, Cfg.EMAC_MAC_MFL);
}

private void emac_reset(EmacRegs* regs) {
    vst(&regs.ctl, 0);
    Timer.delay_us(200);

    vst(&regs.ctl, 1);
    Timer.delay_us(200);
}

private int _sunxi_write_hwaddr(EmacRegs* regs, ubyte* enetaddr) {
    uint enetaddr_lo = enetaddr[2] | (enetaddr[1] << 8) | (enetaddr[0] << 16);
    uint enetaddr_hi = enetaddr[5] | (enetaddr[4] << 8) | (enetaddr[3] << 16);

    vst(&regs.mac_a0, enetaddr_hi);
    vst(&regs.mac_a1, enetaddr_lo);

    return 0;
}

private int _sunxi_emac_eth_init(EmacRegs* regs, ubyte* enetaddr) {
    return 0;
}

private int _sunxi_emac_eth_recv(EmacRegs* regs, void* packet) {
    return 0;
}

private int _sunxi_emac_eth_send(EmacRegs* regs, void* packet, int len) {
    return 0;
}

private int sunxi_emac_board_setup() {
    return 0;
}
