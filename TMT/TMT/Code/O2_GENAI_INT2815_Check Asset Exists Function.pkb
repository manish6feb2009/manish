create or replace PACKAGE BODY xxgenai_fa_veh_attributes_pkg AS

FUNCTION check_asset_exists_func (
        p_asset_number IN NUMBER
    ) RETURN VARCHAR2 IS
        x_asset_exists CHAR := 'N';
    BEGIN
        SELECT
            'Y'
        INTO x_asset_exists
        FROM
            dual
        WHERE
            EXISTS (
                SELECT
                    1
                FROM
                    xxgenai_fa_mass_additions fba
                WHERE
                    asset_number = p_asset_number
            );

        RETURN x_asset_exists;
    EXCEPTION
        WHEN no_data_found THEN
            x_asset_exists := 'N';
            RETURN x_asset_exists;
    END check_asset_exists_func;

  FUNCTION check_vin_exists_func (
        p_vin_number IN VARCHAR2,
        p_asset_id   IN NUMBER
    ) RETURN NUMBER IS
        x_veh_attr_change_trx_id NUMBER := '';
    BEGIN
        SELECT
            xxfa.veh_attr_change_trx_id
        INTO x_veh_attr_change_trx_id
        FROM
            xxgenai_fa_veh_attributes xxfa
        WHERE
                xxfa.vin_number = p_vin_number
            AND xxfa.asset_id = p_asset_id;

        RETURN x_veh_attr_change_trx_id;
    EXCEPTION
        WHEN no_data_found THEN
            x_veh_attr_change_trx_id := '';
            RETURN x_veh_attr_change_trx_id;
    END check_vin_exists_func;

 PROCEDURE update_vin_attributes_no_aud (
        p_vin_attr_tbl   IN g_veh_attr_tbl_type,
        p_status_out     OUT NOCOPY VARCHAR2,
        p_err_msg_out    OUT NOCOPY VARCHAR2
    ) IS
        x_blk_exc_idx NUMBER;
        x_dml_errors EXCEPTION;
    BEGIN
     p_err_msg_out := p_err_msg_out || 'update 2';
        IF p_vin_attr_tbl.count > 0 THEN
     FORALL x_ctr IN p_vin_attr_tbl.first..p_vin_attr_tbl.last SAVE EXCEPTIONS
                UPDATE xxgenai_fa_veh_attributes
                SET
                   vehicle_type = nvl(p_vin_attr_tbl(x_ctr).vehicle_type,
                                       vehicle_type),
                    concat_eam_category = nvl(p_vin_attr_tbl(x_ctr).concat_eam_category,
                                                concat_eam_category),
                    concat_asset_category = nvl(p_vin_attr_tbl(x_ctr).concat_asset_category,
                                                concat_asset_category),
                    prg_risk_flip_reason = nvl(p_vin_attr_tbl(x_ctr).prg_risk_flip_reason,
                                               prg_risk_flip_reason),
                    prg_risk_flip_date = nvl(p_vin_attr_tbl(x_ctr).prg_risk_flip_date,
                                             prg_risk_flip_date),
                    capitalized_flag = nvl(p_vin_attr_tbl(x_ctr).capitalized_flag,
                                           capitalized_flag),
                    employee_number = nvl(p_vin_attr_tbl(x_ctr).employee_number,
                                          employee_number),
                    model_code = nvl(p_vin_attr_tbl(x_ctr).model_code,
                                     model_code),
                    model_description = nvl(p_vin_attr_tbl(x_ctr).model_description,
                                            model_description),
                    model_year = nvl(p_vin_attr_tbl(x_ctr).model_year,
                                     model_year),
                    contract_number = nvl(p_vin_attr_tbl(x_ctr).contract_number,
                                          contract_number),
                    contract_year = nvl(p_vin_attr_tbl(x_ctr).contract_year,
                                        contract_year),
                    contract_status = nvl(p_vin_attr_tbl(x_ctr).contract_status,
                                          contract_status),
                    make = nvl(p_vin_attr_tbl(x_ctr).make,
                               make),
                    vehicle_status = nvl(p_vin_attr_tbl(x_ctr).vehicle_status,
                                         vehicle_status),
                    vehicle_status_reason = nvl(p_vin_attr_tbl(x_ctr).vehicle_status_reason,
                                                vehicle_status_reason),
                    operating_status = nvl(p_vin_attr_tbl(x_ctr).operating_status,
                                           operating_status),
                    operating_sub_status = nvl(p_vin_attr_tbl(x_ctr).operating_sub_status,
                                               operating_sub_status),
                    registration_date = nvl(p_vin_attr_tbl(x_ctr).registration_date,
                                            registration_date),
                    mileage = nvl(p_vin_attr_tbl(x_ctr).mileage,
                                  mileage),
                    mileage_uom = nvl(p_vin_attr_tbl(x_ctr).mileage_uom,
                                      mileage_uom),
                    license_plate_number = nvl(p_vin_attr_tbl(x_ctr).license_plate_number,
                                               license_plate_number),
                    vehicle_origin_code = nvl(p_vin_attr_tbl(x_ctr).vehicle_origin_code,
                                              vehicle_origin_code),
                    cip_identifier = nvl(p_vin_attr_tbl(x_ctr).cip_identifier,
                                         cip_identifier),
                    leased_out_flag = nvl(p_vin_attr_tbl(x_ctr).leased_out_flag,
                                          leased_out_flag),
                    lease_start_date = nvl(p_vin_attr_tbl(x_ctr).lease_start_date,
                                           lease_start_date),
                    manufacturer_code = nvl(p_vin_attr_tbl(x_ctr).manufacturer_code,
                                            manufacturer_code),
                    sipp_code = nvl(p_vin_attr_tbl(x_ctr).sipp_code,
                                    sipp_code),
                    uvc = nvl(p_vin_attr_tbl(x_ctr).uvc,
                              uvc),
                    lke_eligibility = nvl(p_vin_attr_tbl(x_ctr).lke_eligibility,
                                          lke_eligibility),
                    registration_state_province = nvl(p_vin_attr_tbl(x_ctr).registration_state_province,
                                                      registration_state_province),
                    co2_emissions = nvl(p_vin_attr_tbl(x_ctr).co2_emissions,
                                        co2_emissions),
                    fuel_type = nvl(p_vin_attr_tbl(x_ctr).fuel_type,
                                    fuel_type),
                    inspection_status = nvl(p_vin_attr_tbl(x_ctr).inspection_status,
                                            inspection_status),
                     body_style = nvl(p_vin_attr_tbl(x_ctr).body_style,
                                     body_style),
                    trim = nvl(p_vin_attr_tbl(x_ctr).trim,
                               trim),
                   purchasing_location = nvl(p_vin_attr_tbl(x_ctr).purchasing_location,
                                              purchasing_location),
                    last_rental_location = nvl(p_vin_attr_tbl(x_ctr).last_rental_location,
                                               last_rental_location),
                    sale_location = nvl(p_vin_attr_tbl(x_ctr).sale_location,
                                        sale_location),
                    pickup_location = nvl(p_vin_attr_tbl(x_ctr).pickup_location,
                                          pickup_location),
                    delivery_location = nvl(p_vin_attr_tbl(x_ctr).delivery_location,
                                            delivery_location),
                    mso_receive_date = nvl(p_vin_attr_tbl(x_ctr).mso_receive_date,
                                           mso_receive_date),
                    title_receive_date = nvl(p_vin_attr_tbl(x_ctr).title_receive_date,
                                             title_receive_date),
                    defleet_loc_arrival_date = nvl(p_vin_attr_tbl(x_ctr).defleet_loc_arrival_date,
                                                   defleet_loc_arrival_date),
                    title_ship_date = nvl(p_vin_attr_tbl(x_ctr).title_ship_date,
                                          title_ship_date),
                    theft_conversion_date = nvl(p_vin_attr_tbl(x_ctr).theft_conversion_date,
                                                theft_conversion_date),
                    conversion_recovery_date = nvl(p_vin_attr_tbl(x_ctr).conversion_recovery_date,
                                                   conversion_recovery_date),
                    salvage_date = nvl(p_vin_attr_tbl(x_ctr).salvage_date,
                                       salvage_date),
                    first_rent_date = nvl(p_vin_attr_tbl(x_ctr).first_rent_date,
                                          first_rent_date),
                    last_rent_date = nvl(p_vin_attr_tbl(x_ctr).last_rent_date,
                                         last_rent_date),
                    oem_draft_date = nvl(p_vin_attr_tbl(x_ctr).oem_draft_date,
                                         oem_draft_date),
                    carport_arrival_date = nvl(p_vin_attr_tbl(x_ctr).carport_arrival_date,
                                               carport_arrival_date),
                    bill_of_lading_date = nvl(p_vin_attr_tbl(x_ctr).bill_of_lading_date,
                                              bill_of_lading_date),
                    vehicle_delivery_date = nvl(p_vin_attr_tbl(x_ctr).vehicle_delivery_date,
                                                vehicle_delivery_date),
                    expiration_of_transit = nvl(p_vin_attr_tbl(x_ctr).expiration_of_transit,
                                                expiration_of_transit),
                    manufacturer_group = nvl(p_vin_attr_tbl(x_ctr).manufacturer_group,
                                             manufacturer_group),
                     contract_revision = nvl(p_vin_attr_tbl(x_ctr).contract_revision,
                                            contract_revision),
                    daily_deprn_rate = nvl(p_vin_attr_tbl(x_ctr).daily_deprn_rate,
                                           daily_deprn_rate),
                    daily_deprn_amt = nvl(p_vin_attr_tbl(x_ctr).daily_deprn_amt,
                                          daily_deprn_amt),
                    dep_start_date = nvl(p_vin_attr_tbl(x_ctr).dep_start_date,
                                         dep_start_date),
                    stm_reserve_cleared = nvl(p_vin_attr_tbl(x_ctr).stm_reserve_cleared,
                                              stm_reserve_cleared),
                    excess_penalty_rsrv_clrd = nvl(p_vin_attr_tbl(x_ctr).excess_penalty_rsrv_clrd,
                                                   excess_penalty_rsrv_clrd),
                    prorated_nbv = nvl(p_vin_attr_tbl(x_ctr).prorated_nbv,
                                       prorated_nbv),
                    last_lease_invoice_date = nvl(p_vin_attr_tbl(x_ctr).last_lease_invoice_date,
                                                  last_lease_invoice_date),
                    licensee_lease_amount = nvl(p_vin_attr_tbl(x_ctr).licensee_lease_amount,
                                                licensee_lease_amount),
                    licensee_lease_rate = nvl(p_vin_attr_tbl(x_ctr).licensee_lease_rate,
                                              licensee_lease_rate),
                    licensee_backend_profit = nvl(p_vin_attr_tbl(x_ctr).licensee_backend_profit,
                                                  licensee_backend_profit),
                    damage_lqd_effective_date = nvl(p_vin_attr_tbl(x_ctr).damage_lqd_effective_date,
                                                    damage_lqd_effective_date),
                    legal_hold_effective_date = nvl(p_vin_attr_tbl(x_ctr).legal_hold_effective_date,
                                                    legal_hold_effective_date),
                    expected_sales_date = nvl(p_vin_attr_tbl(x_ctr).expected_sales_date,
                                              expected_sales_date),
                    engine_size = nvl(p_vin_attr_tbl(x_ctr).engine_size,
                                      engine_size),
                    itv_serial = nvl(p_vin_attr_tbl(x_ctr).itv_serial,
                                     itv_serial),
                    pickup_availability_date = nvl(p_vin_attr_tbl(x_ctr).pickup_availability_date,
                                                   pickup_availability_date),
                    pickup_date = nvl(p_vin_attr_tbl(x_ctr).pickup_date,
                                      pickup_date),
                    damage_appraisal_date = nvl(p_vin_attr_tbl(x_ctr).damage_appraisal_date,
                                                damage_appraisal_date),
                    status_streason_chng_date = nvl(nvl(p_vin_attr_tbl(x_ctr).status_streason_chng_date,
                                                        sysdate),
                                                    status_streason_chng_date),
                    control_location = nvl(p_vin_attr_tbl(x_ctr).control_location,
                                           control_location),
                    accounting_location = nvl(p_vin_attr_tbl(x_ctr).accounting_location,
                                              accounting_location),
                    operator_id = nvl(p_vin_attr_tbl(x_ctr).operator_id,
                                      operator_id),
                    concession_location = nvl(p_vin_attr_tbl(x_ctr).concession_location,
                                              concession_location),
                    contract_line_num = nvl(p_vin_attr_tbl(x_ctr).contract_line_num,
                                            contract_line_num),
                    source_asset_id = nvl(p_vin_attr_tbl(x_ctr).source_asset_id,
                                          source_asset_id),
                    creation_source = nvl(p_vin_attr_tbl(x_ctr).creation_source,
                                          creation_source),
                    veh_attr_change_trx_id = nvl(p_vin_attr_tbl(x_ctr).veh_attr_change_trx_id,
                                                 veh_attr_change_trx_id),
                    attribute_category = nvl(p_vin_attr_tbl(x_ctr).attribute_category,
                                             attribute_category),
                    attribute1 = nvl(p_vin_attr_tbl(x_ctr).attribute1,
                                     attribute1),
                    attribute2 = nvl(p_vin_attr_tbl(x_ctr).attribute2,
                                     attribute2),
                    attribute3 = nvl(p_vin_attr_tbl(x_ctr).attribute3,
                                     attribute3),
                    attribute4 = nvl(p_vin_attr_tbl(x_ctr).attribute4,
                                     attribute4),
                    attribute5 = nvl(p_vin_attr_tbl(x_ctr).attribute5,
                                     attribute5),
                    car_class = nvl(p_vin_attr_tbl(x_ctr).car_class,
                                    car_class),
                    usage_type = nvl(p_vin_attr_tbl(x_ctr).usage_type,
                                     usage_type), 
                    last_update_date = nvl(p_vin_attr_tbl(x_ctr).last_update_date,
                                           last_update_date),
                    last_updated_by = nvl(p_vin_attr_tbl(x_ctr).last_updated_by,
                                          last_updated_by) ,
                    last_update_login = nvl(p_vin_attr_tbl(x_ctr).last_update_login,
                                            last_update_login),
                    trx_id_updated_by = nvl(p_vin_attr_tbl(x_ctr).veh_attr_change_trx_id,veh_attr_change_trx_id)
                                        || '-'
                                        || nvl(p_vin_attr_tbl(x_ctr).last_updated_by,last_updated_by)
                WHERE
                        vin_number = p_vin_attr_tbl(x_ctr).vin_number
                    AND asset_id = p_vin_attr_tbl(x_ctr).asset_id;

        COMMIT;

        END IF;

        p_status_out := 'S';
        p_err_msg_out := p_err_msg_out || 'update 3';
    EXCEPTION
        WHEN OTHERS THEN
            p_status_out := 'E';
            p_err_msg_out := substr(SQLERRM,1,200);
    END update_vin_attributes_no_aud;
PROCEDURE copy_vin_attributes (
        p_vin_attr_tbl IN g_veh_attr_tbl_type,
        p_status_out   OUT NOCOPY VARCHAR2,
        p_err_msg_out  OUT NOCOPY VARCHAR2
    ) IS
        x_vin_attr_tbl g_veh_attr_tbl_type;
        x_dml_errors EXCEPTION;
        x_blk_exc_idx  NUMBER;
    BEGIN
        p_status_out := 'S';
        IF p_vin_attr_tbl.count > 0 THEN
            FOR x_copy_idx IN p_vin_attr_tbl.first..p_vin_attr_tbl.last LOOP
                FOR rec_new_asset IN (
                    SELECT
                        vin_number,
                        p_vin_attr_tbl(x_copy_idx).asset_id               AS asset_id,
                        vehicle_type,
                        concat_eam_category,
                        concat_asset_category,
                        prg_risk_flip_reason,
                        prg_risk_flip_date,
                        usage_type,
                        capitalized_flag,
                        vehicle_status,
                        vehicle_status_reason,
                        decode(p_vin_attr_tbl(x_copy_idx).creation_source,
                               'REINSTATEMENT',
                               p_vin_attr_tbl(x_copy_idx).operating_status,
                               operating_status)                          AS operating_status,
                        decode(p_vin_attr_tbl(x_copy_idx).creation_source,
                               'REINSTATEMENT',
                               p_vin_attr_tbl(x_copy_idx).operating_sub_status,
                               operating_sub_status)                      AS operating_sub_status,
                        employee_number,
                        registration_state_province,
                        registration_date,
                        mileage,
                        mileage_uom,
                        license_plate_number,
                        sipp_code,
                        uvc,
                        vehicle_origin_code,
                        cip_identifier,
                        lke_eligibility,
                        fuel_type,
                        inspection_status,
                        last_rental_location,
                        sale_location,
                        control_location,
                        pickup_location,
                        delivery_location,
                        purchasing_location,
                        mso_receive_date,
                        title_receive_date,
                        defleet_loc_arrival_date,
                        title_ship_date,
                        theft_conversion_date,
                        conversion_recovery_date,
                        salvage_date,
                        first_rent_date,
                        last_rent_date,
                        oem_draft_date,
                        carport_arrival_date,
                        bill_of_lading_date,
                        vehicle_delivery_date,
                        expiration_of_transit,
                        model_code,
                        model_description,
                        model_year,
                        car_class,
                        make,
                        manufacturer_code,
                        manufacturer_group,
                        co2_emissions,
                        body_style,
                        trim,
                        leased_out_flag,
                        lease_start_date,
                        contract_number,
                        contract_year,
                        contract_status,
                        contract_revision,
                        daily_deprn_rate,
                        daily_deprn_amt,
                        p_vin_attr_tbl(x_copy_idx).dep_start_date         AS dep_start_date,
                        stm_reserve_cleared,
                        excess_penalty_rsrv_clrd,
                        prorated_nbv,
                        last_lease_invoice_date,
                        licensee_lease_amount,
                        licensee_lease_rate,
                        licensee_backend_profit,
                        damage_lqd_effective_date,
                        legal_hold_effective_date,
                        expected_sales_date,
                        engine_size,
                        itv_serial,
                        pickup_availability_date,
                        pickup_date,
                        damage_appraisal_date,
                        status_streason_chng_date,
                        accounting_location,
                        operator_id,
                        concession_location,
                        contract_line_num,
                        p_vin_attr_tbl(x_copy_idx).source_asset_id        AS source_asset_id,
                        p_vin_attr_tbl(x_copy_idx).creation_source        AS creation_source,
                        p_vin_attr_tbl(x_copy_idx).veh_attr_change_trx_id AS veh_attr_change_trx_id,
                        NULL                                              AS trx_id_updated_by,
                        attribute_category,
                        attribute1,
                        attribute2,
                        attribute3,
                        attribute4,
                        attribute5,
                        sysdate                                           AS creation_date,
                        sysdate                                           AS last_update_date
                        FROM
                        xxgenai_fa_veh_attributes
                    WHERE
                        asset_id = p_vin_attr_tbl(x_copy_idx).source_asset_id
                ) LOOP
                    x_vin_attr_tbl(x_copy_idx).vin_number := rec_new_asset.vin_number;
                    x_vin_attr_tbl(x_copy_idx).asset_id := rec_new_asset.asset_id;
                    x_vin_attr_tbl(x_copy_idx).vehicle_type := rec_new_asset.vehicle_type;
                    x_vin_attr_tbl(x_copy_idx).concat_eam_category := rec_new_asset.concat_eam_category;
                    x_vin_attr_tbl(x_copy_idx).concat_asset_category := rec_new_asset.concat_asset_category;
                    x_vin_attr_tbl(x_copy_idx).prg_risk_flip_reason := rec_new_asset.prg_risk_flip_reason;
                    x_vin_attr_tbl(x_copy_idx).prg_risk_flip_date := rec_new_asset.prg_risk_flip_date;
                    x_vin_attr_tbl(x_copy_idx).usage_type := rec_new_asset.usage_type;
                    x_vin_attr_tbl(x_copy_idx).capitalized_flag := rec_new_asset.capitalized_flag;
                    x_vin_attr_tbl(x_copy_idx).vehicle_status := rec_new_asset.vehicle_status;
                    x_vin_attr_tbl(x_copy_idx).vehicle_status_reason := rec_new_asset.vehicle_status_reason;
                    x_vin_attr_tbl(x_copy_idx).operating_status := rec_new_asset.operating_status;
                    x_vin_attr_tbl(x_copy_idx).operating_sub_status := rec_new_asset.operating_sub_status;
                    x_vin_attr_tbl(x_copy_idx).employee_number := rec_new_asset.employee_number;
                    x_vin_attr_tbl(x_copy_idx).registration_state_province := rec_new_asset.registration_state_province;
                    x_vin_attr_tbl(x_copy_idx).registration_date := rec_new_asset.registration_date;
                    x_vin_attr_tbl(x_copy_idx).mileage := rec_new_asset.mileage;
                    x_vin_attr_tbl(x_copy_idx).mileage_uom := rec_new_asset.mileage_uom;
                    x_vin_attr_tbl(x_copy_idx).license_plate_number := rec_new_asset.license_plate_number;
                    x_vin_attr_tbl(x_copy_idx).sipp_code := rec_new_asset.sipp_code;
                    x_vin_attr_tbl(x_copy_idx).uvc := rec_new_asset.uvc;
                    x_vin_attr_tbl(x_copy_idx).vehicle_origin_code := rec_new_asset.vehicle_origin_code;
                    x_vin_attr_tbl(x_copy_idx).cip_identifier := rec_new_asset.cip_identifier;
                    x_vin_attr_tbl(x_copy_idx).lke_eligibility := rec_new_asset.lke_eligibility;
                    x_vin_attr_tbl(x_copy_idx).fuel_type := rec_new_asset.fuel_type;
                    x_vin_attr_tbl(x_copy_idx).inspection_status := rec_new_asset.inspection_status;
                    x_vin_attr_tbl(x_copy_idx).last_rental_location := rec_new_asset.last_rental_location;
                    x_vin_attr_tbl(x_copy_idx).sale_location := rec_new_asset.sale_location;
                    x_vin_attr_tbl(x_copy_idx).control_location := rec_new_asset.control_location;
                    x_vin_attr_tbl(x_copy_idx).pickup_location := rec_new_asset.pickup_location;
                    x_vin_attr_tbl(x_copy_idx).delivery_location := rec_new_asset.delivery_location;
                    x_vin_attr_tbl(x_copy_idx).purchasing_location := rec_new_asset.purchasing_location;
                    x_vin_attr_tbl(x_copy_idx).mso_receive_date := rec_new_asset.mso_receive_date;
                    x_vin_attr_tbl(x_copy_idx).title_receive_date := rec_new_asset.title_receive_date;
                    x_vin_attr_tbl(x_copy_idx).defleet_loc_arrival_date := rec_new_asset.defleet_loc_arrival_date;
                    x_vin_attr_tbl(x_copy_idx).title_ship_date := rec_new_asset.title_ship_date;
                    x_vin_attr_tbl(x_copy_idx).theft_conversion_date := rec_new_asset.theft_conversion_date;
                    x_vin_attr_tbl(x_copy_idx).conversion_recovery_date := rec_new_asset.conversion_recovery_date;
                    x_vin_attr_tbl(x_copy_idx).salvage_date := rec_new_asset.salvage_date;
                    x_vin_attr_tbl(x_copy_idx).first_rent_date := rec_new_asset.first_rent_date;
                    x_vin_attr_tbl(x_copy_idx).last_rent_date := rec_new_asset.last_rent_date;
                    x_vin_attr_tbl(x_copy_idx).oem_draft_date := rec_new_asset.oem_draft_date;
                    x_vin_attr_tbl(x_copy_idx).carport_arrival_date := rec_new_asset.carport_arrival_date;
                    x_vin_attr_tbl(x_copy_idx).bill_of_lading_date := rec_new_asset.bill_of_lading_date;
                    x_vin_attr_tbl(x_copy_idx).vehicle_delivery_date := rec_new_asset.vehicle_delivery_date;
                    x_vin_attr_tbl(x_copy_idx).expiration_of_transit := rec_new_asset.expiration_of_transit;
                    x_vin_attr_tbl(x_copy_idx).model_code := rec_new_asset.model_code;
                    x_vin_attr_tbl(x_copy_idx).model_description := rec_new_asset.model_description;
                    x_vin_attr_tbl(x_copy_idx).model_year := rec_new_asset.model_year;
                    x_vin_attr_tbl(x_copy_idx).car_class := rec_new_asset.car_class;
                    x_vin_attr_tbl(x_copy_idx).make := rec_new_asset.make;
                    x_vin_attr_tbl(x_copy_idx).manufacturer_code := rec_new_asset.manufacturer_code;
                    x_vin_attr_tbl(x_copy_idx).manufacturer_group := rec_new_asset.manufacturer_group;
                    x_vin_attr_tbl(x_copy_idx).co2_emissions := rec_new_asset.co2_emissions;
                    x_vin_attr_tbl(x_copy_idx).body_style := rec_new_asset.body_style;
                    x_vin_attr_tbl(x_copy_idx).trim := rec_new_asset.trim;
                    x_vin_attr_tbl(x_copy_idx).leased_out_flag := rec_new_asset.leased_out_flag;
                    x_vin_attr_tbl(x_copy_idx).lease_start_date := rec_new_asset.lease_start_date;
                    x_vin_attr_tbl(x_copy_idx).contract_number := rec_new_asset.contract_number;
                    x_vin_attr_tbl(x_copy_idx).contract_year := rec_new_asset.contract_year;
                    x_vin_attr_tbl(x_copy_idx).contract_status := rec_new_asset.contract_status;
                    x_vin_attr_tbl(x_copy_idx).contract_revision := rec_new_asset.contract_revision;
                    x_vin_attr_tbl(x_copy_idx).daily_deprn_rate := rec_new_asset.daily_deprn_rate;
                    x_vin_attr_tbl(x_copy_idx).daily_deprn_amt := rec_new_asset.daily_deprn_amt;
                    x_vin_attr_tbl(x_copy_idx).dep_start_date := rec_new_asset.dep_start_date;
                    x_vin_attr_tbl(x_copy_idx).stm_reserve_cleared := rec_new_asset.stm_reserve_cleared;
                    x_vin_attr_tbl(x_copy_idx).excess_penalty_rsrv_clrd := rec_new_asset.excess_penalty_rsrv_clrd;
                    x_vin_attr_tbl(x_copy_idx).prorated_nbv := rec_new_asset.prorated_nbv;
                    x_vin_attr_tbl(x_copy_idx).last_lease_invoice_date := rec_new_asset.last_lease_invoice_date;
                    x_vin_attr_tbl(x_copy_idx).licensee_lease_amount := rec_new_asset.licensee_lease_amount;
                    x_vin_attr_tbl(x_copy_idx).licensee_lease_rate := rec_new_asset.licensee_lease_rate;
                    x_vin_attr_tbl(x_copy_idx).licensee_backend_profit := rec_new_asset.licensee_backend_profit;
                    x_vin_attr_tbl(x_copy_idx).damage_lqd_effective_date := rec_new_asset.damage_lqd_effective_date;
                    x_vin_attr_tbl(x_copy_idx).legal_hold_effective_date := rec_new_asset.legal_hold_effective_date;
                    x_vin_attr_tbl(x_copy_idx).expected_sales_date := rec_new_asset.expected_sales_date;
                    x_vin_attr_tbl(x_copy_idx).engine_size := rec_new_asset.engine_size;
                    x_vin_attr_tbl(x_copy_idx).itv_serial := rec_new_asset.itv_serial;
                    x_vin_attr_tbl(x_copy_idx).pickup_availability_date := rec_new_asset.pickup_availability_date;
                    x_vin_attr_tbl(x_copy_idx).pickup_date := rec_new_asset.pickup_date;
                    x_vin_attr_tbl(x_copy_idx).damage_appraisal_date := rec_new_asset.damage_appraisal_date;
                    x_vin_attr_tbl(x_copy_idx).status_streason_chng_date := rec_new_asset.status_streason_chng_date;
                    x_vin_attr_tbl(x_copy_idx).accounting_location := rec_new_asset.accounting_location;
                    x_vin_attr_tbl(x_copy_idx).operator_id := rec_new_asset.operator_id;
                    x_vin_attr_tbl(x_copy_idx).concession_location := rec_new_asset.concession_location;
                    x_vin_attr_tbl(x_copy_idx).contract_line_num := rec_new_asset.contract_line_num;
                    x_vin_attr_tbl(x_copy_idx).source_asset_id := rec_new_asset.source_asset_id;
                    x_vin_attr_tbl(x_copy_idx).creation_source := rec_new_asset.creation_source;
                    x_vin_attr_tbl(x_copy_idx).veh_attr_change_trx_id := rec_new_asset.veh_attr_change_trx_id;
                    x_vin_attr_tbl(x_copy_idx).trx_id_updated_by := rec_new_asset.trx_id_updated_by;
                    x_vin_attr_tbl(x_copy_idx).attribute_category := rec_new_asset.attribute_category;
                    x_vin_attr_tbl(x_copy_idx).attribute1 := rec_new_asset.attribute1;
                    x_vin_attr_tbl(x_copy_idx).attribute2 := rec_new_asset.attribute2;
                    x_vin_attr_tbl(x_copy_idx).attribute3 := rec_new_asset.attribute3;
                    x_vin_attr_tbl(x_copy_idx).attribute4 := rec_new_asset.attribute4;
                    x_vin_attr_tbl(x_copy_idx).attribute5 := rec_new_asset.attribute5;
                    x_vin_attr_tbl(x_copy_idx).creation_date := rec_new_asset.creation_date;
         END LOOP;
            END LOOP;

            BEGIN
                FORALL x_copy_idx1 IN x_vin_attr_tbl.first..x_vin_attr_tbl.last SAVE EXCEPTIONS
                    INSERT INTO xxgenai_fa_veh_attributes VALUES x_vin_attr_tbl ( x_copy_idx1 );

            EXCEPTION
                WHEN x_dml_errors THEN
                    p_status_out := 'E';
                    p_err_msg_out := 'Error during Insert';
            END;

        END IF;

    END copy_vin_attributes;
 PROCEDURE populate_veh_attr (
        p_mode         IN VARCHAR2,
        p_vin_attr_tbl IN g_veh_attr_tbl_type,
        p_status_out   OUT VARCHAR2,
        p_err_msg_out  OUT VARCHAR2
    ) IS

        x_veh_attr_change_trx_id NUMBER DEFAULT '';
        x_asset_exists           CHAR DEFAULT 'N';
        x_vin_attr_tbl           g_veh_attr_tbl_type;
        x_vin_attr_tbl1          g_veh_attr_tbl_type;
        x_tmp_ret_stat           CHAR DEFAULT 'S';
        x_no_records_exc         EXCEPTION;
        x_asset_notexist_exc     EXCEPTION;
        x_vin_exists_exc         EXCEPTION;
        x_others_exc             EXCEPTION;
    BEGIN
        p_status_out := 'S';
        x_vin_attr_tbl := p_vin_attr_tbl;
        x_vin_attr_tbl1 := p_vin_attr_tbl;
        IF ( p_vin_attr_tbl.count = 0 ) THEN
            RAISE x_no_records_exc;
        END IF;

        IF p_mode = g_mode_create THEN
            p_err_msg_out := p_err_msg_out || 'inside create';
            FOR x_ctr IN p_vin_attr_tbl.first..p_vin_attr_tbl.last LOOP
                x_veh_attr_change_trx_id := '';
                x_asset_exists := 'N';
                BEGIN
                    x_asset_exists := check_asset_exists_func(p_vin_attr_tbl(x_ctr).asset_id);  
                    IF ( x_asset_exists = 'N' ) THEN
                        RAISE x_asset_notexist_exc;
                        p_err_msg_out := p_err_msg_out || 'VIN exists';
                    END IF;

        x_veh_attr_change_trx_id := check_vin_exists_func(p_vin_number => p_vin_attr_tbl(x_ctr).vin_number, p_asset_id => p_vin_attr_tbl
                    (x_ctr).asset_id);

                    IF ( x_veh_attr_change_trx_id IS NOT NULL ) THEN
                        RAISE x_vin_exists_exc;
                    END IF;
                EXCEPTION
                    WHEN x_asset_notexist_exc THEN
                        p_err_msg_out := 'Asset with Id does not exist in system....hence creating it';
                    WHEN x_vin_exists_exc THEN
                        p_status_out := 'E';
                        p_err_msg_out := 'VIN already exists in Vehicle Attributes';
                    WHEN x_others_exc THEN
                        RAISE x_others_exc;
                END;

            END LOOP;

            IF p_vin_attr_tbl.count > 0 THEN
                p_err_msg_out := p_err_msg_out || 'inside create insert';
                BEGIN
                    FORALL x_ctr IN p_vin_attr_tbl.first..p_vin_attr_tbl.last SAVE EXCEPTIONS
                        INSERT INTO xxgenai_fa_veh_attributes VALUES p_vin_attr_tbl ( x_ctr );

                EXCEPTION
                    WHEN OTHERS THEN
                        p_status_out := 'E';
                        p_err_msg_out := 'Error during Insert: ';
                END;

            END IF;

        ELSIF  p_mode IN (G_MODE_UPDATE , G_MODE_MANUAL_UPDATE)
        THEN 
     p_err_msg_out := p_err_msg_out || 'update';
            dbms_output.put_line('Before calling update vin att proc error message' || p_err_msg_out);

            update_vin_attributes_no_aud(p_vin_attr_tbl => x_vin_attr_tbl1
                          , p_status_out       => p_status_out
                          , p_err_msg_out      => p_err_msg_out);

            dbms_output.put_line('After calling update vin att proc error message '|| p_err_msg_out);
            p_err_msg_out := p_err_msg_out || 'update 1' || x_vin_attr_tbl1.count;

        ELSIF p_mode = G_MODE_COPY
        THEN
            FOR x_ctr in p_vin_attr_tbl.FIRST .. p_vin_attr_tbl.LAST    
            LOOP
                x_veh_attr_change_trx_id := '';
                x_asset_exists := 'N';
                BEGIN
                    x_asset_exists := check_asset_exists_func(p_vin_attr_tbl(x_ctr).asset_id);
                    IF ( x_asset_exists = 'N' ) THEN
                        RAISE x_asset_notexist_exc;
                    END IF;

                    x_veh_attr_change_trx_id := check_vin_exists_func(p_vin_number => p_vin_attr_tbl(x_ctr).vin_number, p_asset_id => p_vin_attr_tbl
                    (x_ctr).asset_id);

                    IF ( x_veh_attr_change_trx_id IS NOT NULL ) THEN
                        RAISE x_vin_exists_exc;
                    END IF;
                EXCEPTION
                    WHEN x_asset_notexist_exc THEN
                        p_status_out := 'E';
                        p_err_msg_out := 'Asset with Id does not exist in system';
                    WHEN x_vin_exists_exc THEN
                        p_status_out := 'E';
                        p_err_msg_out := 'VIN already exists in Vehicle Attributes';
                    WHEN x_others_exc THEN
                        RAISE x_others_exc;
                END;
                END LOOP;
                copy_vin_attributes ( p_vin_attr_tbl => x_vin_attr_tbl
                          , p_status_out       => p_status_out
                          , p_err_msg_out      => p_err_msg_out
                          );
                COMMIT;


        END IF; 
        EXCEPTION
        WHEN OTHERS THEN
            p_status_out := 'E';
            p_err_msg_out := sqlerrm;
    END populate_veh_attr;
PROCEDURE assign_sequence ( p_oic_instance_id       IN NUMBER
                            , p_user                  IN VARCHAR
							, p_status_out       OUT VARCHAR2
							, p_err_msg_out      OUT VARCHAR2 								 
                             )
  IS
   x_array_limit            NUMBER                                       := 10000;
	CURSOR c_eam_rec
    IS
      SELECT 
	     vin_number
		,vehicle_type
		,vehicle_sub_type
		,own_type
		,fleet_category
		,prg_risk_flip_reason
		,vehicle_status
		,vehicle_status_reason
		,registration_state_province
		,asset_description
		,employee_number
		,concession_name
		,mileage
		,mileage_uom
		,license_plate_number
		,fuel_type
		,body_style
		,registration_date
		,prg_risk_flip_date
		,salvage_date
		,damage_lqd_liquidation_date
		,bol_number
		,bill_of_lading_date
		,country_code
		,control_location
		,engine_size
		,eam_datetimestamp
      FROM XXgenai_FA_EAM_ASSET_VIN_STG stg
      WHERE  oic_instance_id               is null
		order by EAM_DATETIMESTAMP ASC;
    TYPE eam_vin_table_type IS TABLE OF c_eam_rec%ROWTYPE
      INDEX BY BINARY_INTEGER;
    eam_vin_tbl        eam_vin_table_type;
  BEGIN
    OPEN c_eam_rec;
    LOOP
      eam_vin_tbl.DELETE;
      FETCH c_eam_rec
       BULK COLLECT 
       INTO eam_vin_tbl
       LIMIT x_array_limit;
      EXIT WHEN eam_vin_tbl.COUNT = 0;
      BEGIN
        FOR j IN eam_vin_tbl.FIRST .. eam_vin_tbl.LAST 
		LOOP
          UPDATE XXgenai_FA_EAM_ASSET_VIN_STG
             SET record_id                  = XXgenai_FA_EAM_ASSET_VIN_STG_S1.nextval
               , last_update_date           = sysdate
			   , last_updated_by            = p_user
              WHERE eam_datetimestamp = eam_vin_tbl (j).eam_datetimestamp
			 AND oic_instance_id IS NULL
			 AND vin_number = eam_vin_tbl (j).vin_number;
			 COMMIT;
        END LOOP;
        END;

	  END LOOP;
    close c_eam_rec;  

      EXCEPTION
      WHEN OTHERS
      THEN
      p_status_out  := 'E';
      p_err_msg_out := SUBSTR (SQLERRM, 1, 200);
  END assign_sequence;
END xxgenai_fa_veh_attributes_pkg;