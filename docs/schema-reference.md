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
<comp name="assembly-name" role="sensor|compute|actuator">
  <description>Human-readable description</description>
  <!-- ports, sensors, visuals, frames, links, buses -->
</comp>
```

| Attribute | Required | Description |
|-----------|----------|-------------|
| `name` | Yes | Unique identifier for the component |
| `role` | No | Component role: `sensor`, `compute`, `actuator` |

---

## Ports

Ports define physical connection interfaces on a device. Each port has a type, position, and geometry for visualization.

### Wired Port Types

- `ethernet` - Ethernet (10/100/1000BASE-T, 100BASE-T1, etc.)
- `SPI` - Serial Peripheral Interface
- `I2C` - Inter-Integrated Circuit
- `UART` - Universal Asynchronous Receiver-Transmitter
- `CAN` - Controller Area Network
- `USB` - Universal Serial Bus
- `JTAG` - Joint Test Action Group (debug)
- `SWD` - Serial Wire Debug

### Port Definition

```xml
<port name="ETH0" type="ethernet">
  <pose>x y z roll pitch yaw</pose>
  <geometry>
    <!-- box, cylinder, or sphere -->
  </geometry>
</port>
```

| Element | Required | Description |
|---------|----------|-------------|
| `<pose>` | Yes | Position and orientation: `x y z roll pitch yaw` (meters, radians) |
| `<geometry>` | No | Physical shape for visualization/interaction |

### Port Geometry Examples

```xml
<!-- Rectangular connector (e.g., RJ45, pin header) -->
<port name="ETH0" type="ethernet">
  <pose>0.022 -0.015 -0.009 0 0 0</pose>
  <geometry>
    <box>
      <size>0.008 0.006 0.003</size>  <!-- x y z in meters -->
    </box>
  </geometry>
</port>

<!-- Circular connector (e.g., barrel jack) -->
<port name="PWR" type="power">
  <pose>0.01 0.02 -0.005 0 0 0</pose>
  <geometry>
    <cylinder>
      <radius>0.002</radius>
      <length>0.004</length>
    </cylinder>
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
    <geometry>
      <!-- optional FOV visualization -->
    </geometry>
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

### Sensor Geometry (Field of View)

Sensors with directional sensing use geometry to visualize their FOV:

```xml
<!-- Circular FOV (single-beam ToF, ultrasonic) -->
<sensor name="rangefinder">
  <optical type="tof">
    <pose>0 0 -0.01 0 0 0</pose>
    <driver name="vl53l1x"/>
    <geometry>
      <cone>
        <radius>0.08</radius>   <!-- base radius at max range -->
        <length>4.0</length>    <!-- max sensing distance -->
      </cone>
    </geometry>
  </optical>
</sensor>

<!-- Rectangular FOV (camera, array-based ToF) -->
<sensor name="camera0">
  <optical type="camera">
    <pose>0 0 0.01 0 0 0</pose>
    <driver name="ov5640"/>
    <geometry>
      <frustum>
        <near>0.01</near>       <!-- near plane distance -->
        <far>10.0</far>         <!-- far plane distance -->
        <hfov>1.2217</hfov>     <!-- horizontal FOV in radians -->
        <vfov>0.9599</vfov>     <!-- vertical FOV in radians -->
      </frustum>
    </geometry>
  </optical>
</sensor>
```

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

<!-- Split IMU (BMI088 style - same IC, separate control) -->
<sensor name="imu1">
  <inertial type="accel">
    <pose>0 0 0.01 0 0 0</pose>
    <driver name="bmi088_accel">
      <axis-align x="X" y="Y" z="Z"/>
    </driver>
  </inertial>
  <inertial type="gyro">
    <pose>0 0 0.01 0 0 0</pose>
    <driver name="bmi088_gyro">
      <axis-align x="X" y="-Y" z="-Z"/>
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

<!-- ToF array sensor with frustum FOV -->
<sensor name="tof">
  <optical type="tof">
    <pose>-0.008 0 0.003 0 0 0</pose>
    <driver name="afbr_s50"/>
    <geometry>
      <frustum>
        <near>0.001</near>
        <far>0.30</far>
        <hfov>0.1047</hfov>
        <vfov>0.1047</vfov>
      </frustum>
    </geometry>
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

3D model references for visualization.

```xml
<visual name="main_board" toggle="optional_group">
  <pose>x y z roll pitch yaw</pose>
  <model href="models/sha-name.glb" sha="full_sha256_hash"/>
</visual>
```

| Attribute | Required | Description |
|-----------|----------|-------------|
| `name` | Yes | Unique visual identifier |
| `toggle` | No | Toggle group for show/hide UI |

| Element | Required | Description |
|---------|----------|-------------|
| `<pose>` | Yes | Position and orientation |
| `<model>` | Yes | GLB model reference with SHA for caching |

---

## Frames

Named reference frames for coordinate transformations.

```xml
<frame name="board_origin">
  <description>Main board origin</description>
  <pose>0 0 0 0 0 0</pose>
</frame>
```

---

## Links (External Connections)

Links describe connections between devices.

### Point-to-Point Links

```xml
<link name="hub_to_sensor">
  <digital>
    <wired type="ethernet">
      <from device="hub" port="ETH0"/>
      <to device="optical_flow" port="ETH0"/>
      <speed>100M</speed>
      <ip from="192.0.2.2" to="192.0.2.1"/>
    </wired>
  </digital>
</link>

<link name="vehicle_to_gcs">
  <digital>
    <wireless type="wifi">
      <from device="vehicle" antenna="wifi0"/>
      <to device="gcs" antenna="wifi0"/>
      <ssid>cognipilot</ssid>
      <ip from="192.168.1.10" to="192.168.1.1"/>
    </wireless>
  </digital>
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

<link name="linear_actuator">
  <physical>
    <translational>
      <axis>1 0 0</axis>
      <limits lower="0" upper="0.1"/>
    </translational>
  </physical>
</link>
```

---

## Buses (Shared Medium)

Buses describe shared communication media with multiple participants.

```xml
<bus name="main_can" type="CAN">
  <bitrate>1000000</bitrate>
  <participant device="hub" port="CAN0" id="0x10"/>
  <participant device="esc_fl" port="CAN0" id="0x20"/>
  <participant device="esc_fr" port="CAN0" id="0x21"/>
  <participant device="esc_rl" port="CAN0" id="0x22"/>
  <participant device="esc_rr" port="CAN0" id="0x23"/>
</bus>

<bus name="sensor_i2c" type="I2C">
  <speed>400000</speed>
  <participant device="hub" port="I2C1" role="controller"/>
  <participant device="baro" port="I2C0" address="0x76"/>
  <participant device="mag" port="I2C0" address="0x1E"/>
</bus>
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

### Cone (Circular FOV)
```xml
<geometry>
  <cone>
    <radius>r</radius>   <!-- base radius at length distance -->
    <length>l</length>   <!-- sensing distance -->
  </cone>
</geometry>
```

### Frustum (Rectangular FOV)
```xml
<geometry>
  <frustum>
    <near>n</near>       <!-- near plane distance -->
    <far>f</far>         <!-- far plane distance -->
    <hfov>h</hfov>       <!-- horizontal FOV in radians -->
    <vfov>v</vfov>       <!-- vertical FOV in radians -->
  </frustum>
</geometry>
```

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

See [mr_mcxn_t1/optical-flow/optical-flow.hcdf](../mr_mcxn_t1/optical-flow/) for a complete example using this schema.
