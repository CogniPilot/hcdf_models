# HCDF Schema Reference

Hardware Configuration Descriptive Format (HCDF) is an XML-based format for describing hardware assemblies, including 3D visualization, sensor configurations, ports, and connectivity.

## Version

Current schema version: `2.0`

```xml
<?xml version="1.0"?>
<hcdf version="2.0">
  <!-- content -->
</hcdf>
```

## Root Element: `<comp>`

The top-level component describing a hardware assembly.

```xml
<comp name="assembly-name" role="sensor|compute|actuator|parent">
  <description>Human-readable description</description>
  <!-- ports, sensors, visuals, frames, network, links, buses -->
</comp>
```

| Attribute | Required | Description |
|-----------|----------|-------------|
| `name` | Yes | Unique identifier for the component |
| `role` | No | Component role: `sensor`, `compute`, `actuator`, `parent` |
| `hwid` | No | Hardware ID (for discovered devices) |

---

## MCU Element: `<mcu>`

Microcontroller units (discovered or predefined).

```xml
<mcu name="spinali-001" hwid="0x12345678abcdef">
  <board>mr_mcxn_t1</board>
  <software name="cerebri">
    <version>1.0.0</version>
    <hash>abc123...</hash>
    <firmware_manifest_uri>https://firmware.example.com/board/app</firmware_manifest_uri>
  </software>
  <discovered>
    <ip>192.168.186.10</ip>
    <port>2</port>
    <last_seen>2026-01-07T12:00:00Z</last_seen>
  </discovered>
</mcu>
```

---

## Software Element

Software running on a device, including firmware update configuration.

```xml
<software name="cerebri">
  <version>1.0.0</version>
  <hash>abc123def456...</hash>
  <firmware_manifest_uri>https://firmware.cognipilot.org/mr_mcxn_t1/optical-flow</firmware_manifest_uri>
  <params><!-- application-specific parameters --></params>
</software>
```

| Element | Required | Description |
|---------|----------|-------------|
| `<version>` | No | Software version string |
| `<hash>` | No | MCUboot image hash for verification |
| `<firmware_manifest_uri>` | No | Base URI for firmware updates (daemon appends `/latest.json`) |
| `<params>` | No | Application-specific parameters |

**Note:** `firmware_manifest_uri` must be explicitly set for firmware update checking. There is no default fallback.

---

## Ports

Ports define physical wired connection interfaces on a device. Each port has a type, optional mesh reference for 3D visualization, and capabilities describing its electrical/protocol characteristics.

### Wired Port Types

- `ethernet` - Ethernet (10/100/1000BASE-T, 100BASE-T1, etc.)
- `SPI` - Serial Peripheral Interface
- `I2C` - Inter-Integrated Circuit
- `UART` - Universal Asynchronous Receiver-Transmitter
- `CAN` - Controller Area Network
- `USB` - Universal Serial Bus
- `JTAG` - Joint Test Action Group (debug)
- `SWD` - Serial Wire Debug
- `POWER` - Power connector
- `CARD` - Card slot (SD, SIM, etc.)

### Port Definition

```xml
<port name="ETH0" type="ethernet" visual="hub_board" mesh="ETH0">
  <capabilities>
    <speed unit="Mbps">1000</speed>
    <standard>1000BASE-T</standard>
  </capabilities>
</port>
```

| Attribute | Required | Description |
|-----------|----------|-------------|
| `name` | Yes | Port identifier (e.g., "ETH0", "CAN0") |
| `type` | Yes | Port type (see list above) |
| `visual` | No | Name of visual element containing the port mesh |
| `mesh` | No | GLTF mesh node name within the visual (for highlighting) |

| Element | Required | Description |
|---------|----------|-------------|
| `<capabilities>` | No | Electrical/protocol characteristics (see below) |
| `<pose>` | No | Position and orientation (only needed for fallback geometry) |
| `<geometry>` | No | Fallback shape if no mesh reference |

### Port Capabilities

The `<capabilities>` element describes the electrical and protocol characteristics of a port.

**When to use `POWER` type ports:** Use for dedicated power connections that carry only power (battery connectors, power distribution, barrel jacks). These have no data protocol.

**When to use power capabilities on data ports:** Many data interfaces also carry power (PoE, PoDL, USB-PD, CAN power pins, I2C power). Add power capabilities to these data ports to document the power delivery specs alongside the data specs.

#### Data Capabilities

| Element | Port Types | Description |
|---------|------------|-------------|
| `<speed>` | ethernet | Network speed with `unit` attribute (typically "Mbps") |
| `<bitrate>` | CAN | Bitrate with `unit` attribute (typically "bps") |
| `<baud>` | UART | Baud rate with `unit` attribute (typically "baud") |
| `<standard>` | ethernet | Physical layer standard (e.g., "1000BASE-T", "1000BASE-T1", "100BASE-TX") |
| `<protocol>` | any | Protocol variants - can appear multiple times (e.g., "CAN-FD", "TSN", "USB-PD") |

#### Power Capabilities (available on any port type)

| Element | Attributes | Description |
|---------|------------|-------------|
| `<voltage>` | `unit`, `min`, `max` | Voltage with range; value is nominal (e.g., `<voltage unit="V" min="7" max="28">12</voltage>`) |
| `<current>` | `unit`, `max` | Maximum current (e.g., `<current unit="A" max="3"/>`) |
| `<power>` | `unit`, `max` | Maximum power in watts (e.g., `<power unit="W" max="36"/>`) |
| `<capacity>` | `unit` | Energy capacity for batteries (e.g., `<capacity unit="Wh">55.5</capacity>`) |
| `<connector>` | - | Physical connector type (e.g., "XT60", "RJ45", "USB-C", "JST-GH") |

### Port Examples

```xml
<!-- Ethernet with mesh reference and capabilities -->
<port name="end0" type="ethernet" visual="hub_board" mesh="rj45">
  <capabilities>
    <speed unit="Mbps">1000</speed>
    <standard>1000BASE-T</standard>
  </capabilities>
</port>

<!-- 100BASE-T1 Ethernet (automotive/industrial single-pair) -->
<port name="end1_5" type="ethernet" visual="t1s_board" mesh="port5">
  <capabilities>
    <speed unit="Mbps">100</speed>
    <standard>100BASE-T1</standard>
  </capabilities>
</port>

<!-- 1000BASE-T1 Ethernet with Power over Data Lines (PoDL) -->
<port name="end1_1" type="ethernet" visual="t1s_board" mesh="port1">
  <capabilities>
    <speed unit="Mbps">1000</speed>
    <standard>1000BASE-T1</standard>
    <protocol>PoDL</protocol>
    <voltage unit="V" min="12" max="48">24</voltage>
    <power unit="W" max="50"/>
  </capabilities>
</port>

<!-- Standard Ethernet with PoE (Power over Ethernet) -->
<port name="eth_poe" type="ethernet" visual="switch" mesh="eth0">
  <capabilities>
    <speed unit="Mbps">1000</speed>
    <standard>1000BASE-T</standard>
    <protocol>PoE+</protocol>
    <voltage unit="V" min="44" max="57">48</voltage>
    <power unit="W" max="30"/>
  </capabilities>
</port>

<!-- CAN-FD port with power pins (common in automotive) -->
<port name="can1" type="CAN" visual="io_board" mesh="can1">
  <capabilities>
    <bitrate unit="bps">500000</bitrate>
    <protocol>CAN-FD</protocol>
    <voltage unit="V" min="8" max="16">12</voltage>
    <current unit="A" max="0.5"/>
  </capabilities>
</port>

<!-- CAN port without power (data only) -->
<port name="can2" type="CAN" visual="io_board" mesh="can2">
  <capabilities>
    <bitrate unit="bps">500000</bitrate>
    <protocol>CAN-FD</protocol>
  </capabilities>
</port>

<!-- UART/Serial port -->
<port name="debug" type="UART" visual="main_board" mesh="debug">
  <capabilities>
    <baud unit="baud">115200</baud>
    <protocol>RS-232</protocol>
  </capabilities>
</port>

<!-- Port with fallback geometry (no mesh available) -->
<port name="CAN0" type="CAN">
  <capabilities>
    <bitrate unit="bps">1000000</bitrate>
    <protocol>CAN-FD</protocol>
  </capabilities>
  <pose>-0.0225 -0.0155 -0.0085 0 0 0</pose>
  <geometry>
    <box>
      <size>0.005 0.004 0.003</size>
    </box>
  </geometry>
</port>

<!-- Simple port with mesh reference only (no capabilities) -->
<port name="sdcard" type="CARD" visual="main_board" mesh="sdcard"></port>

<!-- Power input port with voltage range and max draw -->
<port name="pwr_in" type="POWER" visual="main_board" mesh="pwr">
  <capabilities>
    <voltage unit="V" min="7" max="28">12</voltage>
    <current unit="A" max="3"/>
    <power unit="W" max="36"/>
    <connector>XT30</connector>
  </capabilities>
</port>

<!-- Battery output port with capacity -->
<port name="bat_out" type="POWER" visual="battery" mesh="output">
  <capabilities>
    <voltage unit="V" min="10.5" max="12.6">12</voltage>
    <current unit="A" max="10"/>
    <power unit="W" max="120"/>
    <capacity unit="Wh">55.5</capacity>
    <connector>XT60</connector>
  </capabilities>
</port>

<!-- USB-C power delivery port -->
<port name="usbc_pwr" type="USB" visual="main_board" mesh="usbc">
  <capabilities>
    <voltage unit="V" min="5" max="20">12</voltage>
    <current unit="A" max="3"/>
    <power unit="W" max="60"/>
    <connector>USB-C</connector>
    <protocol>USB-PD</protocol>
  </capabilities>
</port>
```

---

## Antennas

Antennas define wireless connection interfaces. Each antenna has a type, optional mesh reference for 3D visualization, and capabilities describing its RF characteristics.

### Wireless Types

- `wifi` - WiFi (802.11)
- `bluetooth` - Bluetooth/BLE
- `lora` - LoRa
- `cellular` - Cellular (LTE, 5G)
- `uwb` - Ultra-Wideband
- `gnss` - GNSS antenna
- `NFC` - Near-Field Communication

### Antenna Definition

```xml
<antenna name="wifi0" type="wifi" visual="main_board" mesh="ant0">
  <capabilities>
    <band>2.4 GHz</band>
    <band>5 GHz</band>
    <standard>802.11ax</standard>
    <protocol>WPA3</protocol>
    <gain unit="dBi">3.5</gain>
    <polarization>linear</polarization>
  </capabilities>
</antenna>
```

| Attribute | Required | Description |
|-----------|----------|-------------|
| `name` | Yes | Antenna identifier |
| `type` | Yes | Antenna type (see list above) |
| `visual` | No | Name of visual element containing the antenna mesh |
| `mesh` | No | GLTF mesh node name within the visual (for highlighting) |

| Element | Required | Description |
|---------|----------|-------------|
| `<capabilities>` | No | RF characteristics (see below) |
| `<pose>` | No | Position and orientation (only needed for fallback geometry) |
| `<geometry>` | No | Fallback shape if no mesh reference |

### Antenna Capabilities

The `<capabilities>` element describes the RF characteristics of an antenna. All child elements are optional and can appear multiple times where noted.

| Element | Multiple | Description |
|---------|----------|-------------|
| `<band>` | Yes | Frequency band (e.g., "2.4 GHz", "5 GHz", "L1", "L2", "L5") |
| `<standard>` | Yes | PHY/MAC standard (e.g., "802.11ax", "802.15.4", "Bluetooth 5.4") |
| `<protocol>` | Yes | Higher-layer protocol (e.g., "Thread", "6LoWPAN", "Matter", "WPA3") |
| `<gain>` | No | Antenna gain with `unit` attribute (typically "dBi") |
| `<polarization>` | No | Polarization type (e.g., "linear", "circular", "RHCP", "LHCP") |

**Semantic distinction:**
- **`band`**: RF frequency bands the antenna operates on
- **`standard`**: PHY/MAC layer specifications (IEEE standards, Bluetooth specs)
- **`protocol`**: Higher-layer networking protocols built on top of the standards

### Antenna Examples

```xml
<!-- Antenna with mesh reference (preferred) -->
<antenna name="wifi0" type="wifi" visual="main_board" mesh="ant0">
  <capabilities>
    <band>2.4 GHz</band>
    <band>5 GHz</band>
    <standard>802.11ax</standard>
    <gain unit="dBi">2.0</gain>
  </capabilities>
</antenna>

<!-- Antenna with fallback geometry -->
<antenna name="lora0" type="lora">
  <pose>0.02 0 0.01 0 0 0</pose>
  <geometry>
    <cylinder>
      <radius>0.003</radius>
      <length>0.015</length>
    </cylinder>
  </geometry>
  <capabilities>
    <band>915 MHz</band>
    <gain unit="dBi">5.0</gain>
  </capabilities>
</antenna>

<!-- Tri-radio module (Wi-Fi 6 / Bluetooth 5.4 / IEEE 802.15.4) -->
<!-- Example: NXP IW612 (LBES5PL2EL-923) with two antennas -->
<antenna name="mlan0" type="wifi" visual="main_board" mesh="ant0">
  <capabilities>
    <band>2.4 GHz</band>
    <band>5 GHz</band>
    <standard>802.11ax</standard>
    <standard>Bluetooth 5.4</standard>
    <standard>802.15.4</standard>
    <protocol>Thread</protocol>
    <protocol>6LoWPAN</protocol>
    <protocol>Matter</protocol>
    <gain unit="dBi">2.0</gain>
  </capabilities>
</antenna>

<antenna name="bt" type="bluetooth" visual="main_board" mesh="ant1">
  <capabilities>
    <band>2.4 GHz</band>
    <standard>Bluetooth 5.4</standard>
    <standard>802.15.4</standard>
    <protocol>Thread</protocol>
    <protocol>6LoWPAN</protocol>
    <gain unit="dBi">2.0</gain>
  </capabilities>
</antenna>

<!-- GNSS antenna with multiple frequency bands -->
<antenna name="gnss0" type="gnss" visual="main_board" mesh="gnss_ant">
  <capabilities>
    <band>L1</band>
    <band>L2</band>
    <band>L5</band>
    <gain unit="dBi">3.0</gain>
    <polarization>RHCP</polarization>
  </capabilities>
</antenna>

<!-- NFC antenna -->
<antenna name="nfc0" type="NFC" visual="main_board" mesh="nfc">
  <capabilities>
    <band>13.56 MHz</band>
    <protocol>NFC</protocol>
    <gain unit="dBi">2.0</gain>
  </capabilities>
</antenna>
```

---

## Network Configuration

Network configuration describes how a device handles network traffic (switching, bridging, etc.).

### Switch Configuration

For devices with an Ethernet switch (e.g., SJA1105):

```xml
<network>
  <interface name="eth0" type="t1" ports="6">
    <switch chip="sja1105"/>
  </interface>
</network>
```

### Bridge Configuration

For devices that bridge/forward between two ports:

```xml
<network>
  <bridge ports="ETH0,ETH1"/>
</network>
```

---

## Connectivity: Links vs Buses

HCDF uses two connectivity models based on the network type:

| Model | Use Case | Examples |
|-------|----------|----------|
| **Links** | Point-to-point connections (with optional forwarding) | Ethernet, USB, UART |
| **Buses** | Shared medium with multiple participants | CAN, I2C, SPI, Power |

### Key Differences

- **Ethernet** (even daisy-chained): Each device actively forwards packets. Model as **links** between ports.
- **CAN/I2C**: Shared electrical medium. All devices receive all traffic. Model as a **bus** with participants.

---

## Links (Point-to-Point Connections)

Links describe bidirectional connections between two ports. Use links for Ethernet, USB, UART, and other point-to-point or forwarded networks.

### Basic Link

```xml
<link name="hub_to_sensor">
  <wired type="100base-t1">
    <port>navq95/eth0:2</port>
    <port>optical-flow/ETH0</port>
  </wired>
</link>
```

The port reference format is: `device_name/port_name[:switch_port]`

### Link with IP Configuration

```xml
<link name="hub_to_sensor">
  <wired type="100base-t1">
    <port>navq95/eth0:2</port>
    <port>optical-flow/ETH0</port>
    <ip>192.168.186.10</ip>
  </wired>
</link>
```

### Wireless Link

```xml
<link name="vehicle_to_gcs">
  <wireless type="wifi">
    <antenna>vehicle/wifi0</antenna>
    <antenna>gcs/wifi0</antenna>
    <ssid>cognipilot</ssid>
  </wireless>
</link>
```

### Physical Links (Mechanical)

```xml
<link name="arm_joint">
  <physical>
    <fixed/>
  </physical>
</link>

<link name="servo_joint">
  <physical>
    <rotational>
      <axis>0 0 1</axis>
      <limits lower="-1.57" upper="1.57"/>
    </rotational>
  </physical>
</link>
```

### Multi-Level / Daisy-Chain Ethernet

For daisy-chained Ethernet where devices forward packets:

```xml
<!-- Device definitions with bridge configuration -->
<comp name="hub-A">
  <port name="ETH0" type="ethernet"/>
  <port name="ETH1" type="ethernet"/>
  <network>
    <bridge ports="ETH0,ETH1"/>
  </network>
</comp>

<!-- Links form the chain -->
<link name="navq_to_hubA">
  <wired type="100base-t1">
    <port>navq95/eth0:1</port>
    <port>hub-A/ETH0</port>
  </wired>
</link>

<link name="hubA_to_hubB">
  <wired type="100base-t1">
    <port>hub-A/ETH1</port>
    <port>hub-B/ETH0</port>
  </wired>
</link>

<link name="hubB_to_sensor">
  <wired type="100base-t1">
    <port>hub-B/ETH1</port>
    <port>sensor/ETH0</port>
  </wired>
</link>
```

---

## Buses (Shared Medium)

Buses describe shared media where multiple devices are electrically connected to the same wire(s). Use buses for CAN, I2C, SPI, power distribution, and similar shared networks.

### CAN Bus

CAN is a shared medium - all devices receive all messages. The physical wiring order can be captured with the `position` attribute.

```xml
<bus name="main_can" type="CAN" topology="daisy-chain">
  <bitrate>1000000</bitrate>
  <participant device="navq95" port="can0" position="1" terminator="true"/>
  <participant device="esc_fl" port="CAN0" position="2" id="0x20"/>
  <participant device="esc_fr" port="CAN0" position="3" id="0x21"/>
  <participant device="esc_rl" port="CAN0" position="4" id="0x22"/>
  <participant device="esc_rr" port="CAN0" position="5" id="0x23" terminator="true"/>
</bus>
```

| Attribute | Description |
|-----------|-------------|
| `device` | Device name |
| `port` | Port name on the device |
| `position` | Physical order in daisy chain (optional) |
| `id` | CAN node ID (optional) |
| `terminator` | Whether this device has 120ohm termination (optional) |

### I2C Bus

```xml
<bus name="sensor_i2c" type="I2C">
  <speed>400000</speed>
  <participant device="hub" port="I2C1" role="controller"/>
  <participant device="baro" port="I2C0" address="0x76"/>
  <participant device="mag" port="I2C0" address="0x1E"/>
</bus>
```

| Attribute | Description |
|-----------|-------------|
| `role` | `controller` or `target` |
| `address` | I2C address (for targets) |

### SPI Bus

SPI can be modeled as a bus (shared MISO/MOSI/CLK) or as links (per chip-select):

```xml
<bus name="sensor_spi" type="SPI">
  <speed>10000000</speed>
  <participant device="hub" port="SPI0" role="controller"/>
  <participant device="imu" port="SPI0" cs="0"/>
  <participant device="flash" port="SPI0" cs="1"/>
</bus>
```

### Power Bus

Power buses model power distribution networks where multiple devices share a voltage rail. The bus references power ports on devices, which define their electrical specifications (voltage range, max current, max power). This avoids duplicating electrical specs on both the port and the bus.

```xml
<bus name="main_12v" type="power">
  <voltage>12</voltage>
  <participant device="battery" port="bat_out" role="source"/>
  <participant device="navq95" port="pwr_in" role="sink"/>
  <participant device="hub_a" port="pwr_in" role="sink"/>
  <participant device="sensor" port="pwr_in" role="sink"/>
</bus>
```

| Element/Attribute | Description |
|-------------------|-------------|
| `<voltage>` | Nominal bus voltage (V) |
| `role="source"` | Energy provider (battery, PSU, solar panel) |
| `role="sink"` | Energy consumer |

**Power budget calculation:** The bus voltage combined with each device's port capabilities enables:
- **Compatibility check**: Verify source voltage falls within each sink's min/max range
- **Power budget**: Sum of sink `power max` values vs source `power max`
- **Current budget**: Total current draw vs source max current
- **Connector validation**: Warn if connector types don't match

#### Multi-Rail Power Distribution

For systems with multiple voltage rails:

```xml
<!-- Main 12V rail from battery -->
<bus name="main_12v" type="power">
  <voltage>12</voltage>
  <participant device="battery" port="bat_out" role="source"/>
  <participant device="navq95" port="pwr_12v" role="sink"/>
  <participant device="pdb" port="pwr_in" role="sink"/>
</bus>

<!-- 5V rail from power distribution board -->
<bus name="rail_5v" type="power">
  <voltage>5</voltage>
  <participant device="pdb" port="5v_out" role="source"/>
  <participant device="sensor_a" port="pwr_in" role="sink"/>
  <participant device="sensor_b" port="pwr_in" role="sink"/>
  <participant device="sensor_c" port="pwr_in" role="sink"/>
</bus>
```

---

## Sensors

Sensors are organized by category, with type specifying the specific sensor function.

### Sensor Categories and Types

#### `<inertial>` - Motion/Orientation Sensors
| Type | Description |
|------|-------------|
| `accel` | Accelerometer only |
| `gyro` | Gyroscope only |
| `accel_gyro` | Combined IMU (shared driver/config) |

#### `<em>` - Electromagnetic Sensors
| Type | Description |
|------|-------------|
| `mag` | Magnetometer |
| `metal_detector` | Inductive sensing |
| `eddy_current` | Non-destructive testing |
| `emf` | EMF sensor |

#### `<optical>` - Light-Based Sensors
| Type | Description |
|------|-------------|
| `camera` | Visible/IR camera |
| `lidar` | Laser scanner |
| `tof` | Time-of-flight |
| `optical_flow` | Optical flow sensor |

#### `<rf>` - Radio Frequency Sensors
| Type | Description |
|------|-------------|
| `gnss` | GPS/GNSS receiver |
| `uwb` | Ultra-wideband ranging |
| `radar` | Radar |
| `radio_altimeter` | Radio altitude |

#### `<chemical>` - Chemical Sensors
| Type | Description |
|------|-------------|
| `gas` | Gas sensor |
| `ph` | pH sensor |
| `humidity` | Humidity sensor |

#### `<force>` - Force/Pressure Sensors
| Type | Description |
|------|-------------|
| `strain` | Strain gauge |
| `pressure` | Barometer/pressure |
| `torque` | Torque sensor |
| `load_cell` | Load cell |

### Sensor Definition

```xml
<sensor name="imu0">
  <inertial type="accel_gyro">
    <pose>0 0 0.01 0 0 0</pose>
    <driver name="icm45686">
      <axis-align x="Y" y="-X" z="Z"/>
    </driver>
  </inertial>
</sensor>
```

### Driver Axis Alignment

The `<axis-align>` element maps hardware axes to the board reference frame. This matches Zephyr's `axis-align-*` DTS properties.

```xml
<driver name="icm45686">
  <axis-align x="Y" y="-X" z="Z"/>
</driver>
```

| Attribute | Values | Description |
|-----------|--------|-------------|
| `x` | `X`, `-X`, `Y`, `-Y`, `Z`, `-Z` | Output X comes from this hardware axis |
| `y` | `X`, `-X`, `Y`, `-Y`, `Z`, `-Z` | Output Y comes from this hardware axis |
| `z` | `X`, `-X`, `Y`, `-Y`, `Z`, `-Z` | Output Z comes from this hardware axis |

Default (identity): `x="X" y="Y" z="Z"`

### Sensor Field of View (FOV)

Optical sensors can have multiple named FOV elements, each with its own pose, color, and geometry. This supports sensors with multiple optical paths (e.g., ToF with separate emitter/collector).

```xml
<sensor name="tof_sensor">
  <optical type="tof">
    <pose>-0.008 0 0.003 0 0 0</pose>
    <driver name="afbr_s50"/>

    <!-- Collector: rectangular FOV with squint angle -->
    <fov name="collector" color="#4488ff">
      <pose>0 0 0 0 0.0471 0</pose>
      <geometry>
        <pyramidal_frustum>
          <near>0.05</near>
          <far>50.0</far>
          <hfov>0.2164</hfov>
          <vfov>0.0942</vfov>
        </pyramidal_frustum>
      </geometry>
    </fov>

    <!-- Emitter: circular FOV with offset -->
    <fov name="emitter" color="#ff4444">
      <pose>-0.005 0 0 0 0 0</pose>
      <geometry>
        <conical_frustum>
          <near>0.001</near>
          <far>50.0</far>
          <fov>0.0349066</fov>
        </conical_frustum>
      </geometry>
    </fov>
  </optical>
</sensor>
```

| FOV Attribute | Description |
|---------------|-------------|
| `name` | FOV identifier (e.g., "emitter", "collector", "left", "right") |
| `color` | Hex color for visualization (e.g., "#ff4444") |

### Sensor Examples

```xml
<!-- Combined IMU -->
<sensor name="imu0">
  <inertial type="accel_gyro">
    <pose>0.016 -0.001 -0.008 0 0 0</pose>
    <driver name="icm45686">
      <axis-align x="X" y="Y" z="Z"/>
    </driver>
  </inertial>
</sensor>

<!-- Magnetometer -->
<sensor name="mag0">
  <em type="mag">
    <pose>0.021 0.001 -0.010 0 0 0</pose>
    <driver name="bmm350">
      <axis-align x="Y" y="X" z="-Z"/>
    </driver>
  </em>
</sensor>

<!-- Optical flow with single FOV -->
<sensor name="optical_flow">
  <optical type="optical_flow">
    <pose>-0.0005 -0.0002 0.002125 0 0 0</pose>
    <driver name="paa3905"/>
    <fov name="imager" color="#88ff88">
      <geometry>
        <pyramidal_frustum>
          <near>0.08</near>
          <far>50.0</far>
          <hfov>0.733</hfov>
          <vfov>0.733</vfov>
        </pyramidal_frustum>
      </geometry>
    </fov>
  </optical>
</sensor>

<!-- Barometer -->
<sensor name="baro0">
  <force type="pressure">
    <pose>0.005 0.002 -0.009 0 0 0</pose>
    <driver name="bmp581"/>
  </force>
</sensor>
```

---

## Visuals

3D model references for visualization. Multiple visuals can be defined with individual poses.

```xml
<visual name="main_board" toggle="optional_group">
  <pose>x y z roll pitch yaw</pose>
  <model href="models/sha-name.glb" sha="full_sha256_hash"/>
</visual>
```

| Attribute | Required | Description |
|-----------|----------|-------------|
| `name` | Yes | Unique visual identifier |
| `toggle` | No | Toggle group for show/hide UI (e.g., "case") |

| Element | Required | Description |
|---------|----------|-------------|
| `<pose>` | Yes | Position and orientation |
| `<model>` | Yes | GLB model reference with SHA for caching |

### Visual Examples

```xml
<!-- Main PCB -->
<visual name="hub_board">
  <pose>0 0 -0.00945 1.5708 0 1.5708</pose>
  <model href="models/fc0bc0ac-mcxnt1hub.glb" sha="fc0bc0acf368879671c3b21e0ca06ff8ec43219f6d706ea3b019dfda4bbbe14b"/>
</visual>

<!-- Optional case (toggle group) -->
<visual name="case_base" toggle="case">
  <pose>0 0 -0.014 0 3.14159 -1.5708</pose>
  <model href="models/86d9c8c8-base.glb" sha="86d9c8c84b18be7582be497788cfff9dd1c1801d31d0e855335dc3c155003c75"/>
</visual>
```

---

## Frames

Named reference frames for coordinate transformations.

```xml
<frame name="board_origin">
  <description>Main board origin (spinali_optical_flow_link)</description>
  <pose>0 0 0 0 0 0</pose>
</frame>
```

---

## Geometry Primitives

### Box
```xml
<geometry>
  <box>
    <size>x y z</size>  <!-- dimensions in meters -->
  </box>
</geometry>
```

### Cylinder
```xml
<geometry>
  <cylinder>
    <radius>r</radius>   <!-- in meters -->
    <length>l</length>   <!-- in meters -->
  </cylinder>
</geometry>
```

### Sphere
```xml
<geometry>
  <sphere>
    <radius>r</radius>   <!-- in meters -->
  </sphere>
</geometry>
```

### Conical Frustum (Circular FOV)

For circular cross-section fields of view (single-beam sensors, emitters):

```xml
<geometry>
  <conical_frustum>
    <near>0.001</near>   <!-- near plane distance (meters) -->
    <far>50.0</far>      <!-- far plane distance (meters) -->
    <fov>0.035</fov>     <!-- full angle in radians -->
  </conical_frustum>
</geometry>
```

### Pyramidal Frustum (Rectangular FOV)

For rectangular cross-section fields of view (cameras, array sensors):

```xml
<geometry>
  <pyramidal_frustum>
    <near>0.01</near>    <!-- near plane distance (meters) -->
    <far>10.0</far>      <!-- far plane distance (meters) -->
    <hfov>1.2217</hfov>  <!-- horizontal FOV in radians -->
    <vfov>0.9599</vfov>  <!-- vertical FOV in radians -->
  </pyramidal_frustum>
</geometry>
```

### Deprecated Primitives

The following are supported for backwards compatibility but should not be used in new files:

- `<cone>` - Use `<conical_frustum>` instead
- `<frustum>` - Use `<pyramidal_frustum>` instead

---

## Pose Format

All poses are specified as 6 space-separated values:

```
x y z roll pitch yaw
```

- `x y z` - Position in meters
- `roll pitch yaw` - Orientation in radians (Euler angles, extrinsic XYZ / intrinsic ZYX)

Example: `0.01 -0.005 0.002 0 0 1.5708`

---

## Complete Example

```xml
<?xml version="1.0"?>
<hcdf version="2.0">
  <comp name="optical-flow-assembly" role="sensor">
    <description>Optical flow sensor with T1 hub</description>

    <!-- Ports -->
    <port name="ETH0" type="ethernet" visual="hub_board" mesh="ETH0">
      <pose>0.0225 -0.0155 -0.0085 0 0 0</pose>
    </port>
    <port name="CAN0" type="CAN" visual="hub_board" mesh="CAN0">
      <pose>-0.0225 -0.0155 -0.0085 0 0 0</pose>
    </port>

    <!-- Sensors -->
    <sensor name="imu_hub">
      <inertial type="accel_gyro">
        <pose>0.016125 -0.00085 -0.0075 0 0 0</pose>
        <driver name="icm45686">
          <axis-align x="X" y="Y" z="Z"/>
        </driver>
      </inertial>
    </sensor>

    <sensor name="optical_flow">
      <optical type="optical_flow">
        <pose>-0.0005 -0.0002 0.002125 0 0 0</pose>
        <driver name="paa3905"/>
        <fov name="imager" color="#88ff88">
          <geometry>
            <pyramidal_frustum>
              <near>0.08</near>
              <far>50.0</far>
              <hfov>0.733</hfov>
              <vfov>0.733</vfov>
            </pyramidal_frustum>
          </geometry>
        </fov>
      </optical>
    </sensor>

    <!-- Visuals -->
    <visual name="hub_board">
      <pose>0 0 -0.00945 1.5708 0 1.5708</pose>
      <model href="models/fc0bc0ac-mcxnt1hub.glb" sha="fc0bc0ac..."/>
    </visual>

    <!-- Frames -->
    <frame name="board_origin">
      <description>Main board origin</description>
      <pose>0 0 0 0 0 0</pose>
    </frame>
  </comp>

  <!-- Connectivity -->
  <link name="parent_to_sensor">
    <wired type="100base-t1">
      <port>navq95/eth0:2</port>
      <port>optical-flow-assembly/ETH0</port>
    </wired>
  </link>

  <bus name="sensor_can" type="CAN">
    <bitrate>1000000</bitrate>
    <participant device="optical-flow-assembly" port="CAN0"/>
    <participant device="esc_controller" port="CAN0"/>
  </bus>
</hcdf>
```

See the [mr_mcxn_t1](../mr_mcxn_t1/) directory for more complete examples.
