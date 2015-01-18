// RF69.cpp
//
// Copyright (C) 2011 Mike McCauley
// $Id: RF69.cpp,v 1.4 2014/04/01 04:57:08 mikem Exp mikem $

#include <RF69.h>
#if defined MPIDE
#include <peripheral/int.h>
#define memcpy_P memcpy
#define ATOMIC_BLOCK_START unsigned int __status = INTDisableInterrupts(); {
#define ATOMIC_BLOCK_END } INTRestoreInterrupts(__status);
#elif defined ARDUINO
#include <util/atomic.h>
#define ATOMIC_BLOCK_START     ATOMIC_BLOCK(ATOMIC_RESTORESTATE) {
#define ATOMIC_BLOCK_END }
#endif

// Interrupt vectors for the 2 Arduino interrupt pins
// Each interrupt can be handled by a different instance of RF69, allowing you to have
// 2 or more RF69s per Arduino
RF69* RF69::_RF69ForInterrupt[RF69_NUM_INTERRUPTS] = {0, 0, 0};

// These are indexed by the values of ModemConfigChoice
// Stored in flash (program) memory to save SRAM
// It is important to keep the modulation index for FSK between 0.5 and 10
// modulation index = 2 * Fdev / BR
// Note that I have not had much success with FSK with Fd > ~5
#define CONFIG_FSK (RF69_DATAMODUL_DATAMODE_PACKET | RF69_DATAMODUL_MODULATIONTYPE_FSK | RF69_DATAMODUL_MODULATIONSHAPING_FSK_NONE)
#define CONFIG_GFSK (RF69_DATAMODUL_DATAMODE_PACKET | RF69_DATAMODUL_MODULATIONTYPE_FSK | RF69_DATAMODUL_MODULATIONSHAPING_FSK_BT0_5)
#define CONFIG_OOK (RF69_DATAMODUL_DATAMODE_PACKET | RF69_DATAMODUL_MODULATIONTYPE_OOK | RF69_DATAMODUL_MODULATIONSHAPING_OOK_NONE)
#define CONFIG_NOWHITE (RF69_PACKETCONFIG1_PACKETFORMAT_VARIABLE | RF69_PACKETCONFIG1_DCFREE_NONE | RF69_PACKETCONFIG1_CRC_ON | RF69_PACKETCONFIG1_ADDRESSFILTERING_NONE)
PROGMEM static const RF69::ModemConfig MODEM_CONFIG_TABLE[] =
{
    //  02,        03,   04,   05,   06,   19,   37
    // FSK, No Manchester, no shaping, no whitening, CRC, no address filtering
    { CONFIG_FSK,  0x3e, 0x80, 0x00, 0x52, 0x56, CONFIG_NOWHITE}, // FSK_Rb2Fd5
    { CONFIG_FSK,  0x34, 0x15, 0x00, 0x27, 0x56, CONFIG_NOWHITE}, // FSK_Rb2_4Fd2_4
    { CONFIG_FSK,  0x1a, 0x0b, 0x00, 0x4f, 0x55, CONFIG_NOWHITE}, // FSK_Rb4_8Fd4_8
    { CONFIG_FSK,  0x0d, 0x05, 0x00, 0x9d, 0x54, CONFIG_NOWHITE}, // FSK_Rb9_6Fd9_6
    { CONFIG_FSK,  0x06, 0x83, 0x01, 0x3b, 0x53, CONFIG_NOWHITE}, // FSK_Rb19_2Fd19_2
    { CONFIG_FSK,  0x03, 0x41, 0x02, 0x75, 0x52, CONFIG_NOWHITE}, // FSK_Rb38_4Fd38_4
    { CONFIG_FSK,  0x02, 0x2c, 0x07, 0xae, 0x4a, CONFIG_NOWHITE}, // FSK_Rb57_6Fd120
    { CONFIG_FSK,  0x01, 0x00, 0x08, 0x22, 0x41, CONFIG_NOWHITE}, // FSK_Rb125Fd125
    { CONFIG_FSK,  0x00, 0x80, 0x10, 0x00, 0x40, CONFIG_NOWHITE}, // FSK_Rb250Fd250
    { CONFIG_FSK,  0x02, 0x40, 0x03, 0x33, 0x42, CONFIG_NOWHITE}, // FSK_Rb55555Fd50 

    //  02,        03,   04,   05,   06,   19,   37
    // GFSK (BT=0.5), No Manchester, BT=0.5 shaping, no whitening, CRC, no address filtering
    { CONFIG_GFSK, 0x3e, 0x80, 0x00, 0x52, 0x56, CONFIG_NOWHITE}, // FSK_Rb2Fd5
    { CONFIG_GFSK, 0x34, 0x15, 0x00, 0x27, 0x56, CONFIG_NOWHITE}, // FSK_Rb2_4Fd2_4
    { CONFIG_GFSK, 0x1a, 0x0b, 0x00, 0x4f, 0x55, CONFIG_NOWHITE}, // FSK_Rb4_8Fd4_8
    { CONFIG_GFSK, 0x0d, 0x05, 0x00, 0x9d, 0x54, CONFIG_NOWHITE}, // FSK_Rb9_6Fd9_6
    { CONFIG_GFSK, 0x06, 0x83, 0x01, 0x3b, 0x53, CONFIG_NOWHITE}, // FSK_Rb19_2Fd19_2
    { CONFIG_GFSK, 0x03, 0x41, 0x02, 0x75, 0x52, CONFIG_NOWHITE}, // FSK_Rb38_4Fd38_4
    { CONFIG_GFSK, 0x02, 0x2c, 0x07, 0xae, 0x4a, CONFIG_NOWHITE}, // FSK_Rb57_6Fd120
    { CONFIG_GFSK, 0x01, 0x00, 0x08, 0x22, 0x41, CONFIG_NOWHITE}, // FSK_Rb125Fd125
    { CONFIG_GFSK, 0x00, 0x80, 0x10, 0x00, 0x40, CONFIG_NOWHITE}, // FSK_Rb250Fd250
    { CONFIG_GFSK, 0x02, 0x40, 0x03, 0x33, 0x42, CONFIG_NOWHITE}, // FSK_Rb55555Fd50 

    //  02,        03,   04,   05,   06,   19,   37
    // OOK, No Manchester, no shaping, no whitening, CRC, no address filtering
    // Caution: this mode has been observed to not be reliable when encryption is enabled
    // Also it does not interoperate with RF22 in similar mode.
//    { CONFIG_OOK,  0x68, 0x2b, 0x00, 0x00, 0x51, CONFIG_NOWHITE}, // OOK_Rb1_2Bw75
};
RF69::RF69(uint8_t slaveSelectPin, uint8_t interrupt, GenericSPIClass *spi)
{
    _slaveSelectPin = slaveSelectPin;
    _interrupt = interrupt;
    _idleMode = RF69_OPMODE_MODE_STDBY;
    _mode = RF69_MODE_IDLE; // We start up in idle mode
    _rxGood = 0;
    _rxBad = 0;
    _txGood = 0;
    _spi = spi;

    // Arrange for all messages to be admitted. Sublclasses may change this.
    _thisAddress  = RF69_BROADCAST_ADDRESS;
    _txHeaderTo   = RF69_BROADCAST_ADDRESS;
    _txHeaderFrom = RF69_BROADCAST_ADDRESS;
}

boolean RF69::init()
{
    // Wait for RF69 POR (up to 10msec)
    delay(10);

    // Initialise the slave select pin
    pinMode(_slaveSelectPin, OUTPUT);
    digitalWrite(_slaveSelectPin, HIGH);

    // start the SPI library:
    // Note the RF69 wants mode 0, MSB first and default to 1 Mbps
    _spi->begin();
    _spi->setDataMode(SPI_MODE0);
    _spi->setBitOrder(MSBFIRST);
    _spi->setClockDivider(SPI_CLOCK_DIV16);  // (16 Mhz / 16) = 1 MHz
    delay(100);

    // Software reset the device
    reset();

    // Get the device type and check it
    // This also tests whether we are really connected to a device
    // My test devices return 0x24
    _deviceType = spiRead(RF69_REG_10_VERSION);
    if (_deviceType == 00 ||
	_deviceType == 0xff)
	return false;

    // Set up interrupt handler
    if (_interrupt == 0)
    {
	_RF69ForInterrupt[0] = this;
	attachInterrupt(0, RF69::isr0, RISING);
    }
    else if (_interrupt == 1)
    {
	_RF69ForInterrupt[1] = this;
	attachInterrupt(1, RF69::isr1, RISING);  
    }
    else if (_interrupt == 2)
    {
	_RF69ForInterrupt[2] = this;
	attachInterrupt(2, RF69::isr2, RISING);  
    }
    else
	return false;

    setMode(_idleMode);

    // Configure important RF69 registers
    // Here we set up the standard packet format for use by the RF69 library:
    // 4 bytes preamble
    // 2 SYNC words 2d, d4
    // 2 CRC CCITT octets computed on the header, length and data (this in the modem config data)
    // 0 to 61 bytes data???? REVISIT: check this
    // We dont use the RF69s address checking: instead we prepend our own headers to the beginning
    // of the RF69 payload
    spiWrite(RF69_REG_3C_FIFOTHRESH, RF69_FIFOTHRESH_TXSTARTCONDITION_NOTEMPTY | 0x0f); // thresh 15 is default
    // RSSITHRESH is default
//    spiWrite(RF69_REG_29_RSSITHRESH, 220); // -110 dbM
    // SYNCCONFIG is default. SyncSize is set later by setSyncWords()
//    spiWrite(RF69_REG_2E_SYNCCONFIG, RF69_SYNCCONFIG_SYNCON); // auto, tolerance 0
    // PAYLOADLENGTH is default
//    spiWrite(RF69_REG_38_PAYLOADLENGTH, RF69_FIFO_SIZE); // max size only for RX
    // PACKETCONFIG 2 is default 
    spiWrite(RF69_REG_6F_TESTDAGC, RF69_TESTDAGC_CONTINUOUSDAGC_IMPROVED_LOWBETAOFF);

    // Some of these can be changed by the user if necessary.
    // Set up default configuration

    uint8_t syncwords[] = { 0x2d, 0xd4 };
    setSyncWords(syncwords, sizeof(syncwords)); // Same as RF22's
    // Some slow, reliable default speed and modulation
    setModemConfig(FSK_Rb2Fd5);
    // 3 would be sufficient, but this is the same as RF22's
    setPreambleLength(4);
    // An innocuous ISM frequency, same as RF22's
    setFrequency(434.0);
    // No encryption
    setEncryptionKey(NULL);
    // +13dBm, same as power-on default
    setTxPower(13); 

    return true;
}

// C++ level interrupt handler for this instance
// RF69 is unusual in that it has several interrupt lines, and not a single, combined one.
// On Moteino, only one of the several interrupt lines (DI0) from the RF69 is connnected to the processor.
// We use this to get PACKETSDENT and PAYLOADRADY interrupts.
void RF69::handleInterrupt()
{
//    Serial.println("interrupt");
    // Get the interrupt cause
    uint8_t irqflags2 = spiRead(RF69_REG_28_IRQFLAGS2);
    if (_mode == RF69_MODE_TX && (irqflags2 & RF69_IRQFLAGS2_PACKETSENT))
    {
	// A transmitter message has been fully sent
	setModeIdle(); // Clears FIFO
//	Serial.println("PACKETSENT");
    }
    // Must look for PAYLOADREADY, not CRCOK, since only PAYLOADREADY occurs _after_ AES decryption
    // has been done
    if (_mode == RF69_MODE_RX && (irqflags2 & RF69_IRQFLAGS2_PAYLOADREADY))
    {
	// A complete message has been received with good CRC
	_lastRssi = -((int8_t)(spiRead(RF69_REG_24_RSSIVALUE) >> 1));
	setModeIdle();
	// Save it in our buffer
	readFifo();
//	Serial.println("PAYLOADREADY");
    }
}

// Low level function reads the FIFO and checks the address
// Caution: since we put our headers in what the RF69 considers to be the payload, if encryption is enabled
// we have to suffer the cost of decryption before we can determine whether the address is acceptable. 
// Performance issue?
void RF69::readFifo()
{
    ATOMIC_BLOCK_START;
    digitalWrite(_slaveSelectPin, LOW);
    _spi->transfer(RF69_REG_00_FIFO); // Send the start address with the write mask off
    uint8_t payloadlen = _spi->transfer(0); // First byte is payload len (counting the headers)
    if (payloadlen <= RF69_MAX_ENCRYPTABLE_PAYLOAD_LEN &&
	payloadlen >= RF69_HEADER_LEN)
    {
	_rxHeaderTo = _spi->transfer(0);
	// Check addressing
	if (_promiscuous ||
	    _rxHeaderTo == _thisAddress ||
	    _rxHeaderTo == RF69_BROADCAST_ADDRESS)
	{
	    // Get the rest of the headers
	    _rxHeaderFrom  = _spi->transfer(0);
	    _rxHeaderId    = _spi->transfer(0);
	    _rxHeaderFlags = _spi->transfer(0);
	    // And now the real payload
	    for (_bufLen = 0; _bufLen < (payloadlen - RF69_HEADER_LEN); _bufLen++)
		_buf[_bufLen] = _spi->transfer(0);
	    _rxBufValid = true;
	}
    }
    digitalWrite(_slaveSelectPin, HIGH);
    ATOMIC_BLOCK_END;
    // Any junk remaining in the FIFO will be cleared next time we go to receive mode.
}

// These are low level functions that call the interrupt handler for the correct
// instance of RF69.
// 2 interrupts allows us to have 2 different devices
void RF69::isr0()
{
    if (_RF69ForInterrupt[0])
	_RF69ForInterrupt[0]->handleInterrupt();
}
void RF69::isr1()
{
    if (_RF69ForInterrupt[1])
	_RF69ForInterrupt[1]->handleInterrupt();
}
void RF69::isr2()
{
    if (_RF69ForInterrupt[2])
	_RF69ForInterrupt[2]->handleInterrupt();
}

void RF69::reset()
{
    // cant do this with the RF69
}

uint8_t RF69::spiRead(uint8_t reg)
{
    uint8_t val;

    ATOMIC_BLOCK_START;
    digitalWrite(_slaveSelectPin, LOW);
    _spi->transfer(reg & ~RF69_SPI_WRITE_MASK); // Send the address with the write mask off
    val = _spi->transfer(0); // The written value is ignored, reg value is read
    digitalWrite(_slaveSelectPin, HIGH);
    ATOMIC_BLOCK_END;
    return val;
}

void RF69::spiWrite(uint8_t reg, uint8_t val)
{
    ATOMIC_BLOCK_START;
    digitalWrite(_slaveSelectPin, LOW);
    _spi->transfer(reg | RF69_SPI_WRITE_MASK); // Send the address with the write mask on
    _spi->transfer(val); // New value follows
    digitalWrite(_slaveSelectPin, HIGH);
    ATOMIC_BLOCK_END;
}

void RF69::spiBurstRead(uint8_t reg, uint8_t* dest, uint8_t len)
{
    ATOMIC_BLOCK_START;
    digitalWrite(_slaveSelectPin, LOW);
    _spi->transfer(reg & ~RF69_SPI_WRITE_MASK); // Send the start address with the write mask off
    while (len--)
	*dest++ = _spi->transfer(0);
    digitalWrite(_slaveSelectPin, HIGH);
    ATOMIC_BLOCK_END;
}

void RF69::spiBurstWrite(uint8_t reg, const uint8_t* src, uint8_t len)
{
    ATOMIC_BLOCK_START;
    digitalWrite(_slaveSelectPin, LOW);
    _spi->transfer(reg | RF69_SPI_WRITE_MASK); // Send the start address with the write mask on
    while (len--)
	_spi->transfer(*src++);
    digitalWrite(_slaveSelectPin, HIGH);
    ATOMIC_BLOCK_END;
}

int8_t RF69::temperatureRead()
{
    // Caution: must be ins standby.
//    setModeIdle();
    spiWrite(RF69_REG_4E_TEMP1, RF69_TEMP1_TEMPMEASSTART); // Start the measurement
    while (spiRead(RF69_REG_4E_TEMP1) & RF69_TEMP1_TEMPMEASRUNNING)
	; // Wait for the measurement to complete
    return -(int8_t)spiRead(RF69_REG_4F_TEMP2) - 40;
}

boolean RF69::setFrequency(float centre, float afcPullInRange)
{
    // Frf = FRF / FSTEP
    uint32_t frf = (centre * 1000000.0) / RF69_FSTEP;
    spiWrite(RF69_REG_07_FRFMSB, (frf >> 16) & 0xff);
    spiWrite(RF69_REG_08_FRFMID, (frf >> 8) & 0xff);
    spiWrite(RF69_REG_09_FRFLSB, frf & 0xff);

    // afcPullInRange is not used
    return true;
}

int8_t RF69::rssiRead()
{
    // Force a new value to be measured
    // Hmmm, this hangs forever!
#if 0
    spiWrite(RF69_REG_23_RSSICONFIG, RF69_RSSICONFIG_RSSISTART);
    while (!(spiRead(RF69_REG_23_RSSICONFIG) & RF69_RSSICONFIG_RSSIDONE))
	;
#endif
    return -((int8_t)(spiRead(RF69_REG_24_RSSIVALUE) >> 1));
}

void RF69::setMode(uint8_t mode)
{
    uint8_t opmode = spiRead(RF69_REG_01_OPMODE);
    opmode &= ~RF69_OPMODE_MODE;
    opmode |= (mode & RF69_OPMODE_MODE);
    spiWrite(RF69_REG_01_OPMODE, opmode);

    // Wait for mode to change.
    while (!(spiRead(RF69_REG_27_IRQFLAGS1) & RF69_IRQFLAGS1_MODEREADY))
	;
}

void RF69::setModeIdle()
{
    if (_mode != RF69_MODE_IDLE)
    {
	setMode(_idleMode);
	_mode = RF69_MODE_IDLE;
    }
}

void RF69::setModeRx()
{
    if (_mode != RF69_MODE_RX)
    {
	spiWrite(RF69_REG_25_DIOMAPPING1, RF69_DIOMAPPING1_DIO0MAPPING_01); // Set interrupt line 0 PayloadReady
	setMode(RF69_OPMODE_MODE_RX); // Clears FIFO
	_mode = RF69_MODE_RX;
    }
}

void RF69::setModeTx()
{
    if (_mode != RF69_MODE_TX)
    {
	spiWrite(RF69_REG_25_DIOMAPPING1, RF69_DIOMAPPING1_DIO0MAPPING_00); // Set interrupt line 0 PacketSent
	setMode(RF69_OPMODE_MODE_TX); // Clears FIFO
	_mode = RF69_MODE_TX;
    }
}

uint8_t  RF69::mode()
{
    return _mode;
}

void RF69::setTxPower(int8_t power)
{
    uint8_t palevel;
    if (power < -18)
	power = -18;

    // See http://www.hoperf.com/upload/rfchip/RF69-V1.2.pdf section 3.3.6
    // for power formulas
    if (power >= 14)
    {
	// Need PA1+PA2
	palevel = RF69_PALEVEL_PA1ON | RF69_PALEVEL_PA2ON | ((power + 14) & RF69_PALEVEL_OUTPUTPOWER);
#if 0
	if (power >= 18)
	{
	    // Also need 20dBm boost settings, not implemented yet, see section 3.3.7
	    palevel = RF69_PALEVEL_PA1ON | RF69_PALEVEL_PA2ON | ((power + 11) & RF69_PALEVEL_OUTPUTPOWER);
	}
#endif
    }
    else
    {
	// -18dBm to +13dBm
	palevel = RF69_PALEVEL_PA0ON | ((power + 18) & RF69_PALEVEL_OUTPUTPOWER);
    }

    spiWrite(RF69_REG_11_PALEVEL, palevel);
}

// Sets registers from a canned modem configuration structure
void RF69::setModemRegisters(const ModemConfig* config)
{
    spiBurstWrite(RF69_REG_02_DATAMODUL,     &config->reg_02, 5);
    spiWrite(RF69_REG_19_RXBW,                config->reg_19);
    spiWrite(RF69_REG_37_PACKETCONFIG1,       config->reg_37);
}

// Set one of the canned FSK Modem configs
// Returns true if its a valid choice
boolean RF69::setModemConfig(ModemConfigChoice index)
{
    if (index > (sizeof(MODEM_CONFIG_TABLE) / sizeof(ModemConfig)))
        return false;

    ModemConfig cfg;
    memcpy_P(&cfg, &MODEM_CONFIG_TABLE[index], sizeof(RF69::ModemConfig));
    setModemRegisters(&cfg);

    return true;
}

void RF69::setPreambleLength(uint16_t bytes)
{
    spiWrite(RF69_REG_2C_PREAMBLEMSB, bytes >> 8);
    spiWrite(RF69_REG_2D_PREAMBLELSB, bytes & 0xff);
}

void RF69::setSyncWords(const uint8_t* syncWords, uint8_t len)
{
    uint8_t syncconfig = spiRead(RF69_REG_2E_SYNCCONFIG);
    if (syncWords && len && len <= 4)
    {
	spiBurstWrite(RF69_REG_2F_SYNCVALUE1, syncWords, len);
	syncconfig |= RF69_SYNCCONFIG_SYNCON;
    }
    else
	syncconfig &= ~RF69_SYNCCONFIG_SYNCON;
    syncconfig &= ~RF69_SYNCCONFIG_SYNCSIZE;
    syncconfig |= (len-1) << 3;
    spiWrite(RF69_REG_2E_SYNCCONFIG, syncconfig);
}

void RF69::setEncryptionKey(uint8_t* key)
{
    if (key)
    {
	spiBurstWrite(RF69_REG_3E_AESKEY1, key, 16);
	spiWrite(RF69_REG_3D_PACKETCONFIG2, spiRead(RF69_REG_3D_PACKETCONFIG2) | RF69_PACKETCONFIG2_AESON);
    }
    else
    {
	spiWrite(RF69_REG_3D_PACKETCONFIG2, spiRead(RF69_REG_3D_PACKETCONFIG2) & ~RF69_PACKETCONFIG2_AESON);
    }
}

boolean RF69::available()
{
    setModeRx(); // Make sure we are receiving
    return _rxBufValid;
}

// Blocks until a valid message is received
void RF69::waitAvailable()
{
    while (!available())
	;
}

// Blocks until a valid message is received or timeout expires
// Return true if there is a message available
// Works correctly even on millis() rollover
bool RF69::waitAvailableTimeout(uint16_t timeout)
{
    unsigned long starttime = millis();
    while ((millis() - starttime) < timeout)
        if (available())
           return true;
    return false;
}

void RF69::waitPacketSent()
{
    while (_mode == RF69_MODE_TX)
	;
}

bool RF69::waitPacketSent(uint16_t timeout)
{
    unsigned long starttime = millis();
    while ((millis() - starttime) < timeout)
        if (_mode != RF69_MODE_TX) // Any previous transmit finished?
           return true;
    return false;
}

// Diagnostic help
void RF69::printBuffer(const char* prompt, const uint8_t* buf, uint8_t len)
{
#ifdef RF69_HAVE_SERIAL
    uint8_t i;

    Serial.println(prompt);
    for (i = 0; i < len; i++)
    {
	if (i % 16 == 15)
	    Serial.println(buf[i], HEX);
	else
	{
	    Serial.print(buf[i], HEX);
	    Serial.print(' ');
	}
    }
    Serial.println(' ');
#endif
}

boolean RF69::recv(uint8_t* buf, uint8_t* len)
{
    if (!available())
	return false;

    ATOMIC_BLOCK_START;
    if (*len > _bufLen)
	*len = _bufLen;
    memcpy(buf, _buf, *len);
    ATOMIC_BLOCK_END;
    _rxBufValid = false; // Got the most recent message
//    printBuffer("recv:", buf, *len);
    return true;
}

boolean RF69::send(const uint8_t* data, uint8_t len)
{
    if (len > RF69_MAX_MESSAGE_LEN)
	return false;

    waitPacketSent(); // Make sure we dont interrupt an outgoing message
    setModeIdle(); // Prevent RX while filling the fifo

    ATOMIC_BLOCK_START;
    digitalWrite(_slaveSelectPin, LOW);
    _spi->transfer(RF69_REG_00_FIFO | RF69_SPI_WRITE_MASK); // Send the start address with the write mask on
    _spi->transfer(len + RF69_HEADER_LEN); // Include length of headers
    // First the 4 headers
    _spi->transfer(_txHeaderTo);
    _spi->transfer(_txHeaderFrom);
    _spi->transfer(_txHeaderId);
    _spi->transfer(_txHeaderFlags);
    // Now the payload
    while (len--)
	_spi->transfer(*data++);
    digitalWrite(_slaveSelectPin, HIGH);
    ATOMIC_BLOCK_END;

    setModeTx(); // Start the transmitter
    return true;
}

void RF69::setHeaderTo(uint8_t to)
{
    _rxHeaderTo = to;
}

void RF69::setHeaderFrom(uint8_t from)
{
    _rxHeaderFrom = from;
}

void RF69::setHeaderId(uint8_t id)
{
    _rxHeaderId = id;
}

void RF69::setHeaderFlags(uint8_t flags)
{
    _rxHeaderFlags = flags;
}

uint8_t RF69::headerTo()
{
    return _rxHeaderTo;
}

uint8_t RF69::headerFrom()
{
    return _rxHeaderFrom;
}

uint8_t RF69::headerId()
{
    return _rxHeaderId;
}

uint8_t RF69::headerFlags()
{
    return _rxHeaderFlags;
}

void RF69::setPromiscuous(boolean promiscuous)
{
    _promiscuous = promiscuous;
}

int8_t RF69::lastRssi()
{
    return _lastRssi;
}
