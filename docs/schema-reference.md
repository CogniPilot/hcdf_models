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

Ports define physical wired connection interfaces on a device. Each port has a type, position, and can reference a mesh in a visual for 3D interaction.

### Wired Port Types

- `ethernet` - Ethernet (10/100/1000BASE-T, 100BASE-T1, etc.)
- `SPI` - Serial Peripheral Interface
- `I2C` - Inter-Integrated Circuit
- `UART` - Universal Asynchronous Receiver-Transmitter
- `CAN` - Controller Area Network
- `USB` - Universal Serial Bus
- `JTAG` - Joint Test Action Group (debug)
- `SWD` - Serial Wire Debug
- `power` - Power connector

### Port Definition

```xml
<port name="ETH0" type="ethernet" visual="hub_board" mesh="ETH0">
  <pose>x y z roll pitch yaw</pose>
  <geometry>
    <!-- optional: box, cylinder, or sphere for fallback visualization -->
  </geometry>
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
| `<pose>` | Yes | Position and orientation: `x y z roll pitch yaw` (meters, radians) |
| `<geometry>` | No | Fallback shape if no mesh reference |

### Port Examples

```xml
<!-- Port with mesh reference (preferred) -->
<port name="ETH0" type="ethernet" visual="hub_board" mesh="ETH0">
  <pose>0.0225 -0.0155 -0.0085 0 0 0</pose>
</port>

<!-- Port with fallback geometry -->
<port name="CAN0" type="CAN">
  <pose>-0.0225 -0.0155 -0.0085 0 0 0</pose>
  <geometry>
    <box>
      <size>0.005 0.004 0.003</size>
    </box>
  </geometry>
</port>
```

---

## Antennas

Antennas define wireless connection interfaces.

### Wireless Types

- `wifi` - WiFi (802.11)
- `bluetooth` - Bluetooth/BLE
- `lora` - LoRa
- `cellular` - Cellular (LTE, 5G)
- `uwb` - Ultra-Wideband
- `gnss` - GNSS antenna

```xml
<antenna name="wifi0" type="wifi">
  <pose>0.02 0 0.01 0 0 0</pose>
  <geometry>
    <cylinder>
      <radius>0.003</radius>
      <length>0.015</length>
    </cylinder>
  </geometry>
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
| **Buses** | Shared medium with multiple participants | CAN, I2C, SPI |

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

Buses describe shared communication media where multiple devices are electrically connected to the same wire(s). Use buses for CAN, I2C, SPI, and similar shared media.

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
