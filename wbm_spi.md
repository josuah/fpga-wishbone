Handshake for Clock Domain Crossing
===================================

Transmission
------------
The part that transmits data through SPI, from the FPGA's Wishbone
bus to the microcontroller.

For the TX part, the Wishbone-clocked module submits a request
that the SPI-clocked module receive.

* The Wishbone-clocked writes through `handshake_wb`.
* The SPI-clocked module writes through `handshake_spi`.

```
		 :    :   :       :        :       :
		 :    :____________________:       :
handshake_data  XXXXXXX____________________XXXXXXXXXXXXX
		 :    :    ________________:       :
handshake_wb    __________/       :        \____________
		 :    :   :       :________________:
handshake_spi   __________________/        :       \____
		 :    :   :       :        :       :
		(1)  (2) (3)     (4)      (5)     (6)
```

1. Initial situation: both handshake signals are low.
   The **SPI** module is waiting anything to happen on `handshake_wb`.

2. Before anything, the **Wishbone** module fills `handshake_data` and
   waits one entire clock to make sure that it is stable.

3. Now that the data is stable, the **Wishbone** module sets `handshake_wb`
   high telling that data is ready to be picked.
   It now waits that `handshake_spi` goes high.

4. Once the **SPI** module saw that `hanshake_wb` went high.
   It first copies `handshake_data`.
   One clock later, it sets `handshake_spi` high to mean that it received
   the data.
   It now waits that `handshake_spi` goes low.

5. Once the **Wishbone** module saw that `handshake_spi` went high,
   it can set `handshake_data` to whatever it likes, such as the next
   data to be sent, and sets `handshake_wb` low.
   It now waits that `handshake_spi` goes low.

6. Once the **SPI** module saw that hanshake_wb went low, it knows
   that the Wishbone module is fully done and sets `handshake_spi` low.
   The cycle is over and restarts to (1).


Reception
---------
The part that receives data from SPI, from the microcontroller to
the FPGA's Wishbone bus.

For the RX part, the SPI-clocked module submits a request that the
Wishbone-clocked module receive.

* The Wishbone-clocked writes through `handshake_wb`.
* The SPI-clocked module writes through `handshake_spi`.

```
		 :    :   :       :        :       :
		 :    :____________________:       :
handshake_data	XXXXXXX____________________XXXXXXXXXXXXX
		 :    :   :       :________________:
handshake_wb	__________________/        :       \____
		 :    :    ________________:       :
handshake_spi	__________/       :        \____________
		 :    :   :       :        :       :
		(1)  (2) (3)     (4)      (5)     (6)
```

1. Initial situation: both handshake signals are low.
   The **Wishbone** module is waiting anything to happen on `handshake_spi`.

2. Before anything, the **SPI** module fills `handshake_data` and
   waits one entire clock to make sure that it is stable.

3. Now that the data is stable, the **SPI** module sets `handshake_spi`
   high telling that data is ready to be picked.
   It now waits that `handshake_wishbone` goes high.

4. Once the **Wishbone** module saw that `hanshake_spi` went high.
   It first copies `handshake_data`.
   One clock later, it sets `handshake_wb` high to mean that it received
   the data.
   It now waits that `handshake_wb` goes low.

5. Once the **SPI** module saw that `handshake_wb` went high,
   it can set `handshake_data` to whatever it likes, such as the next
   data to be sent, and sets `handshake_spi` low.
   It now waits that `handshake_wb` goes low.

6. Once the **Wishbone** module saw that hanshake_wb went low, it knows
   that the SPI module is fully done and sets `handshake_wb` low.
   The cycle is over and restarts to (1).
