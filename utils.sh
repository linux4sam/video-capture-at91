#!/bin/sh

version() {
	echo "$@" | awk -F. '{ printf("%03d%03d%03d\n", $1,$2,$3); }'
}

get_entity_name() {
        local sensor_name=$(media-ctl -p  | grep "entity" | grep $1 | cut -f 4 -d ' ')
        local sensor_num=$(media-ctl -p  | grep "entity" | grep $1 | cut -f 5 -d ' ')
        printf "%s %s" ${sensor_name} ${sensor_num}
}

get_scaler_name() {
	local kernel_version=$(uname -r | awk -F- '{print $1}')
	local kernel_extraversion=$(uname -r | awk -F- '{print $2}')
	local scaler=atmel_isc_scaler

	if [ "$(version "${kernel_version}")" -ge "$(version "6.2.0")" ]; then
		scaler=microchip_isc_scaler
	elif [[ "$(version "${kernel_version}")" -ge "$(version "6.1.0")" ]] && \
	     [[ "${kernel_extraversion}" == *"linux4microchip"* ]]; then
		scaler=microchip_isc_scaler
	fi

	printf "%s" "${scaler}"
}
