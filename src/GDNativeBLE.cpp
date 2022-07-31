#include "GDNativeBLE.h"

#include <thread>

using namespace godot;

void GDNativeBLE::_init() {
	// Initialize
	server_address = "01:23:45:67:89:AB";
	disposed = false;
	
	// Setup callback functions
	ble_events.callback_on_device_disconnected = [&](std::string msg) {
		if (!disposed) {
			emit_signal("device_disconnected", this, String(msg.c_str()));
		}
	};
	ble_events.callback_on_device_connected = [&]() {
		if (!disposed) {
			emit_signal("device_connected", this);
		}
	};
	ble_events.callback_on_scan_found = [&](NativeBLE::DeviceDescriptor device) {
		if (!disposed) {
			devices.push_back(device);
			emit_signal("device_found", this, String(device.name.c_str()), String(device.address.c_str()), int(devices.size()));
		}
	};
	ble_events.callback_on_scan_start = [&]() {
		if (!disposed) {
			emit_signal("scan_started", this);
		}
	};
	ble_events.callback_on_scan_stop = [&]() {
		if (!disposed) {
			emit_signal("scan_stopped", this);
		}
	};
	ble.setup(ble_events);
}

void GDNativeBLE::_process(float delta) { 
	// Do nothing...
}

void GDNativeBLE::_register_methods() {
	// Properties
	register_property<GDNativeBLE, String>("default_server_adress", &GDNativeBLE::server_address, "01:23:45:67:89:AB");

	// Signals callbacks
	register_signal<GDNativeBLE>((char *)"data_received", "node", GODOT_VARIANT_TYPE_OBJECT, "service", GODOT_VARIANT_TYPE_STRING, "characteristic", GODOT_VARIANT_TYPE_STRING, "data", GODOT_VARIANT_TYPE_STRING);
	register_signal<GDNativeBLE>((char *)"notified", "node", GODOT_VARIANT_TYPE_OBJECT, "service", GODOT_VARIANT_TYPE_STRING, "characteristic", GODOT_VARIANT_TYPE_STRING, "data", GODOT_VARIANT_TYPE_STRING);
	register_signal<GDNativeBLE>((char *)"indicated", "node", GODOT_VARIANT_TYPE_OBJECT, "service", GODOT_VARIANT_TYPE_STRING, "characteristic", GODOT_VARIANT_TYPE_STRING, "data", GODOT_VARIANT_TYPE_STRING);
	
	register_signal<GDNativeBLE>((char *)"device_disconnected", "node", GODOT_VARIANT_TYPE_OBJECT, "message", GODOT_VARIANT_TYPE_STRING);
	register_signal<GDNativeBLE>((char *)"device_connected", "node", GODOT_VARIANT_TYPE_OBJECT);
	register_signal<GDNativeBLE>((char *)"device_found", "node", GODOT_VARIANT_TYPE_OBJECT, "name", GODOT_VARIANT_TYPE_STRING, "address", GODOT_VARIANT_TYPE_STRING, "discovered_index", GODOT_VARIANT_TYPE_INT);
	register_signal<GDNativeBLE>((char *)"scan_started", "node", GODOT_VARIANT_TYPE_OBJECT);
	register_signal<GDNativeBLE>((char *)"scan_stopped", "node", GODOT_VARIANT_TYPE_OBJECT);

	// Wrapped methods
	register_method("scan_start", &GDNativeBLE::scan_start);
	register_method("scan_stop", &GDNativeBLE::scan_stop);
	register_method("scan_is_active", &GDNativeBLE::scan_is_active);
	register_method("scan_timeout", &GDNativeBLE::scan_timeout);
	register_method("is_connected", &GDNativeBLE::is_connected);
	register_method("connect", &GDNativeBLE::connect);
	register_method("write_request", &GDNativeBLE::write_request);
	register_method("write_command", &GDNativeBLE::write_command);
	register_method("read", &GDNativeBLE::read);
	register_method("notify", &GDNativeBLE::notify);
	register_method("indicate", &GDNativeBLE::indicate);
	register_method("unsubscribe", &GDNativeBLE::unsubscribe);
	register_method("disconnect", &GDNativeBLE::disconnect);
	register_method("dispose", &GDNativeBLE::dispose);
}

void GDNativeBLE::scan_start() {
	ble.scan_start();
}

void GDNativeBLE::scan_stop() {
	ble.scan_stop();
}

const bool GDNativeBLE::scan_is_active() {
	return ble.scan_is_active();
}

void GDNativeBLE::scan_timeout(const unsigned int timeout_ms) {
	ble.scan_timeout(timeout_ms);
}

const bool GDNativeBLE::is_connected() {
	return ble.is_connected();
}

void GDNativeBLE::connect(const unsigned int index) {
	if(index == 0) {
		ble.connect(server_address.utf8().get_data());
	} else {
		if (index <= devices.size()) {
			ble.connect(devices[index - 1].address);
		}
	}
}

void GDNativeBLE::write_request(const String service, const String characteristic, const String data) {
	ble.write_request(service.utf8().get_data(), characteristic.utf8().get_data(), data.utf8().get_data());
}

void GDNativeBLE::write_command(const String service, const String characteristic, const String data) {
	ble.write_command(service.utf8().get_data(), characteristic.utf8().get_data(), data.utf8().get_data());
}

void GDNativeBLE::read(const String service, const String characteristic) {
	ble.read(service.utf8().get_data(), characteristic.utf8().get_data(), 
		[&, service, characteristic](const uint8_t* data, uint32_t length) {
			char chars[length + 1];
			memcpy(chars, data, length);
			chars[length] = '\0';
			emit_signal("data_received", this, service, characteristic, String(chars));
		});
}

void GDNativeBLE::notify(const String service, const String characteristic) {
	ble.notify(service.utf8().get_data(), characteristic.utf8().get_data(), 
		[&, service, characteristic](const uint8_t* data, uint32_t length) {
			char chars[length + 1];
			memcpy(chars, data, length);
			chars[length] = '\0';
			emit_signal("notified", this, service, characteristic, String(chars));
		}
	);	
}

void GDNativeBLE::indicate(const String service, const String characteristic) {
	ble.indicate(service.utf8().get_data(), characteristic.utf8().get_data(), 
		[&, service, characteristic](const uint8_t* data, uint32_t length) {
			char chars[length + 1];
			memcpy(chars, data, length);
			chars[length] = '\0';
			emit_signal("indicated", this, service, characteristic, String(chars));
		}
	);	
}

void GDNativeBLE::unsubscribe(const String service, const String characteristic) {
	ble.unsubscribe(service.utf8().get_data(), characteristic.utf8().get_data());
}

void GDNativeBLE::disconnect() {
	ble.disconnect();
}

void GDNativeBLE::dispose() {
	disposed = true;
}
