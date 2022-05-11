Handshake for Clock Domain Crossing
===================================
Taking the example of the `wbm_spi_tx.v` core:
The part that transmits data through SPI, from the FPGA's Wishbone bus to the microcontroller.

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
   The SPI module is waiting anything to happen on `handshake_wb`.

2. Before anything, the Wishbone module sets `handshake_data` and waits one entire clock to make sure that it is stable.

3. Now that the data is stable, the Wishbone module sets `handshake_wb` high telling that data is ready to be picked.
   It now waits that `handshake_spi` goes high.

4. Once the SPI module noticed that hanshake_wb went high.
   It first copies `handshake_data`.
   One clock later, it sets `handshake_wb` up to mean it received the data.
   It now waits that `handshake_wb` goes low.

5. Once the Wishbone module noticed that `handshake_spi` went high, it can set `handshake_data` to whatever it likes, such as the next data to be sent.
   It now waits that `handshake_spi` goes low.

6. Once the SPI module noticed that hanshake_wb went low, it knows that the Wishbone module is done.
   It can set `handshake_spi` low again.
   The cycle is over and restarts to (1).
