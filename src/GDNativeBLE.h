#pragma once

#include <Godot.hpp>
#include <Sprite.hpp>

#include <NativeBleController.h>

namespace godot {
	class GDNativeBLE : public Node {
		GODOT_CLASS(GDNativeBLE, Node)

		private:
			NativeBLE::CallbackHolder ble_events;
			NativeBLE::DeviceDescriptor device;
			NativeBLE::NativeBleController ble;
			std::vector<NativeBLE::DeviceDescriptor> devices;
			std::thread* scan_thread;

			bool disposed;
			String server_address;
			unsigned int scan_timeout_ms;

		public:
			// Constructor
			GDNativeBLE() = default;
			~GDNativeBLE() = default;

			// GD methods
			void _init();
			void _process(float delta);
			static void _register_methods();
		
		private:
			// Wrapper
			void scan_start();
			void scan_stop();
			const bool scan_is_active();
			void scan_timeout(const unsigned int timeout_ms);
			const bool is_connected();
			void connect();
			void write_request(const String service, const String characteristic, const String data);
			void write_command(const String service, const String characteristic, const String data);
			void read(const String service, const String characteristic);
			void notify(const String service, const String characteristic);
			void indicate(const String service, const String characteristic);
			void unsubscribe(const String service, const String characteristic);
			void disconnect();
			void dispose();
	};
}
