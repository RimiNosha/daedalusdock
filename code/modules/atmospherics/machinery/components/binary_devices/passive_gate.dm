/*

Passive gate is similar to the regular pump except:
* It doesn't require power
* Can not transfer low pressure to higher pressure (so it's more like a valve where you can control the flow)
* Passes gas when output pressure lower than target pressure

*/

/obj/machinery/atmospherics/components/binary/passive_gate
	icon_state = "passgate_map-3"
	name = "passive gate"
	desc = "A one-way air valve that does not require power. Passes gas when the output pressure is lower than the target pressure."
	can_unwrench = TRUE
	shift_underlay_only = FALSE
	interaction_flags_machine = INTERACT_MACHINE_OFFLINE | INTERACT_MACHINE_WIRES_IF_OPEN | INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_OPEN_SILICON | INTERACT_MACHINE_SET_MACHINE
	construction_type = /obj/item/pipe/directional
	pipe_state = "passivegate"
	use_power = NO_POWER_USE
	///Set the target pressure the component should arrive to
	var/target_pressure = ONE_ATMOSPHERE
	///Variable for radio frequency
	var/frequency = 0
	///Variable for radio id
	var/id = null
	///Stores the radio connection
	var/datum/radio_frequency/radio_connection

/obj/machinery/atmospherics/components/binary/passive_gate/CtrlClick(mob/user)
	if(can_interact(user))
		on = !on
		investigate_log("was turned [on ? "on" : "off"] by [key_name(user)]", INVESTIGATE_ATMOS)
		update_appearance()
	return ..()

/obj/machinery/atmospherics/components/binary/passive_gate/AltClick(mob/user)
	if(can_interact(user))
		target_pressure = MAX_OUTPUT_PRESSURE
		investigate_log("was set to [target_pressure] kPa by [key_name(user)]", INVESTIGATE_ATMOS)
		balloon_alert(user, "pressure output set to [target_pressure] kPa")
		update_appearance()
	return ..()

/obj/machinery/atmospherics/components/binary/passive_gate/Destroy()
	SSpackets.remove_object(src,frequency)
	return ..()

/obj/machinery/atmospherics/components/binary/passive_gate/update_icon_nopipes()
	cut_overlays()
	icon_state = "passgate_off-[set_overlay_offset(piping_layer)]"
	if(on)
		add_overlay(get_pipe_image(icon, "passgate_on-[set_overlay_offset(piping_layer)]"))

/obj/machinery/atmospherics/components/binary/passive_gate/process_atmos()
	if(!on)
		return

	var/datum/gas_mixture/air1 = airs[1]
	var/datum/gas_mixture/air2 = airs[2]
	var/input_starting_pressure = air1.returnPressure()

	var/pressure_delta = input_starting_pressure - target_pressure

	var/transfer_moles = (target_pressure/air1.volume)*air1.total_moles
	transfer_moles = min(transfer_moles, calculate_transfer_moles(air1, air2, pressure_delta))
	if(pump_gas_passive(air1, air2, calculate_transfer_moles(air1, air2, pressure_delta)) >= 0)//pump_gas() will return a negative number if no flow occurred
		update_parents()

//Radio remote control

/**
 * Called in atmos_init(), used to change or remove the radio frequency from the component
 * Arguments:
 * * -new_frequency: the frequency that should be used for the radio to attach to the component, use 0 to remove the radio
 */
/obj/machinery/atmospherics/components/binary/passive_gate/proc/set_frequency(new_frequency)
	SSpackets.remove_object(src, frequency)
	frequency = new_frequency
	if(frequency)
		radio_connection = SSpackets.add_object(src, frequency, filter = RADIO_ATMOSIA)

/**
 * Called in atmos_init(), send the component status to the radio device connected
 */
/obj/machinery/atmospherics/components/binary/passive_gate/proc/broadcast_status()
	if(!radio_connection)
		return

	var/datum/signal/signal = new(src, list(
		"tag" = id,
		"device" = "AGP",
		"power" = on,
		"target_output" = target_pressure,
		"sigtype" = "status"
	))
	radio_connection.post_signal(signal, filter = RADIO_ATMOSIA)

/obj/machinery/atmospherics/components/binary/passive_gate/relaymove(mob/living/user, direction)
	if(!on || direction != dir)
		return
	. = ..()

/obj/machinery/atmospherics/components/binary/passive_gate/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AtmosPump", name)
		ui.open()

/obj/machinery/atmospherics/components/binary/passive_gate/ui_data()
	var/data = list()
	data["on"] = on
	data["pressure"] = round(target_pressure)
	data["max_pressure"] = round(MAX_OUTPUT_PRESSURE)
	return data

/obj/machinery/atmospherics/components/binary/passive_gate/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("power")
			on = !on
			investigate_log("was turned [on ? "on" : "off"] by [key_name(usr)]", INVESTIGATE_ATMOS)
			. = TRUE
		if("pressure")
			var/pressure = params["pressure"]
			if(pressure == "max")
				pressure = MAX_OUTPUT_PRESSURE
				. = TRUE
			else if(text2num(pressure) != null)
				pressure = text2num(pressure)
				. = TRUE
			if(.)
				target_pressure = clamp(pressure, 0, ONE_ATMOSPHERE*100)
				investigate_log("was set to [target_pressure] kPa by [key_name(usr)]", INVESTIGATE_ATMOS)
	update_appearance()

/obj/machinery/atmospherics/components/binary/passive_gate/atmos_init()
	..()
	if(frequency)
		set_frequency(frequency)

/obj/machinery/atmospherics/components/binary/passive_gate/receive_signal(datum/signal/signal)
	if(!signal.data["tag"] || (signal.data["tag"] != id) || (signal.data["sigtype"]!="command"))
		return

	var/old_on = on //for logging

	if("power" in signal.data)
		on = text2num(signal.data["power"])

	if("power_toggle" in signal.data)
		on = !on

	if("set_output_pressure" in signal.data)
		target_pressure = clamp(text2num(signal.data["set_output_pressure"]),0,ONE_ATMOSPHERE*100)

	if(on != old_on)
		investigate_log("was turned [on ? "on" : "off"] by a remote signal", INVESTIGATE_ATMOS)

	if("status" in signal.data)
		broadcast_status()
		return

	broadcast_status()
	update_appearance()

/obj/machinery/atmospherics/components/binary/passive_gate/can_unwrench(mob/user)
	. = ..()
	if(. && on)
		to_chat(user, span_warning("You cannot unwrench [src], turn it off first!"))
		return FALSE


/obj/machinery/atmospherics/components/binary/passive_gate/layer2
	piping_layer = 2
	icon_state = "passgate_map-2"

/obj/machinery/atmospherics/components/binary/passive_gate/layer4
	piping_layer = 4
	icon_state = "passgate_map-4"
