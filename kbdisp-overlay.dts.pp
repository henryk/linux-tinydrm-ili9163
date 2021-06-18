# 1 "kbdisp-overlay.dts"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "kbdisp-overlay.dts"
/dts-v1/;
/plugin/;

# 1 "../raspberrypi-linux/include/dt-bindings/gpio/gpio.h" 1
# 5 "kbdisp-overlay.dts" 2

/ {
    compatible = "brcm,bcm2835";

    fragment@0 {
            target = <&spidev0>;
            __overlay__ {
                    status = "disabled";
            };
    };


    fragment@1 {
        target = <&spi0>;

            __overlay__ {
            #address-cells = <1>;
            #size-cells = <0>;
            status = "okay";

            cs-gpios = <&gpio 8 1>;
            num-chipselects = <1>;

            display@0 {
                compatible = "newhaven,1.8-128160EF", "ilitek,ili9163";
                reg = <0>;
                spi-max-frequency = <320000>;
                dc-gpios = <&gpio 22 0>;
                reset-gpios = <&gpio 25 1>;
                rotation = <180>;
                buswidth = <8>;
                spi-3wire;
            };
        };
    };
};
