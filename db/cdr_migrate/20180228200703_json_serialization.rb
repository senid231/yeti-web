class JsonSerialization < ActiveRecord::Migration
  def up

    execute %q{

alter table cdr.cdr
  add column customer_external_id bigint,
  add column customer_auth_external_id bigint,
  add column customer_acc_vat numeric,
  add column customer_acc_external_id bigint,
  add column routing_tag_ids smallint[],
  add column vendor_external_id bigint,
  add column vendor_acc_external_id bigint,
  add orig_gw_external_id bigint,
  add term_gw_external_id bigint,
  add failed_resource_type_id smallint,
  add failed_resource_id bigint,
  add customer_price_no_vat numeric,
  add customer_duration integer,
  add vendor_duration integer,
  add customer_auth_name varchar;

alter table cdr.cdr_archive
  add column customer_external_id bigint,
  add column customer_auth_external_id bigint,
  add column customer_acc_vat numeric,
  add column customer_acc_external_id bigint,
  add column routing_tag_ids smallint[],
  add column vendor_external_id bigint,
  add column vendor_acc_external_id bigint,
  add orig_gw_external_id bigint,
  add term_gw_external_id bigint,
  add failed_resource_type_id smallint,
  add failed_resource_id bigint,
  add customer_price_no_vat numeric,
  add customer_duration integer,
  add vendor_duration integer,
  add customer_auth_name varchar;

create type switch.dynamic_cdr_data_ty as (
    customer_id integer,
    customer_external_id bigint,
    vendor_id integer,
    vendor_external_id bigint,
    customer_acc_id integer,
    customer_acc_external_id bigint,
    customer_acc_vat numeric,
    vendor_acc_id integer,
    vendor_acc_external_id bigint,
    customer_auth_id integer,
    customer_auth_external_id bigint,
    customer_auth_name varchar,
    destination_id bigint,
    destination_prefix character varying,
    dialpeer_id bigint,
    dialpeer_prefix character varying,
    orig_gw_id integer,
    orig_gw_external_id bigint,
    term_gw_id integer,
    term_gw_external_id bigint,
    routing_group_id integer,
    rateplan_id integer,
    destination_initial_rate numeric,
    destination_next_rate numeric,
    destination_initial_interval integer,
    destination_next_interval integer,
    destination_rate_policy_id smallint,
    dialpeer_initial_interval integer,
    dialpeer_next_interval integer,
    dialpeer_next_rate numeric,
    destination_fee numeric,
    dialpeer_initial_rate numeric,
    dialpeer_fee numeric,
    dst_prefix_in character varying,
    dst_prefix_out character varying,
    src_prefix_in character varying,
    src_prefix_out character varying,
    src_name_in character varying,
    src_name_out character varying,
    diversion_in character varying,
    diversion_out character varying,
    auth_orig_protocol_id smallint,
    auth_orig_ip inet,
    auth_orig_port integer,
    dst_country_id integer,
    dst_network_id integer,
    dst_prefix_routing character varying,
    src_prefix_routing character varying,
    routing_plan_id integer,
    lrn character varying,
    lnp_database_id smallint,
    from_domain character varying,
    to_domain character varying,
    ruri_domain character varying,
    src_area_id integer,
    dst_area_id integer,
    routing_tag_ids smallint[],
    pai_in character varying,
    ppi_in character varying,
    privacy_in character varying,
    rpid_in character varying,
    rpid_privacy_in character varying,
    pai_out character varying,
    ppi_out character varying,
    privacy_out character varying,
    rpid_out character varying,
    rpid_privacy_out character varying,
    customer_acc_check_balance boolean,
    destination_reverse_billing boolean,
    dialpeer_reverse_billing boolean
);

CREATE OR REPLACE FUNCTION switch.writecdr(
    i_is_master boolean,
    i_node_id integer,
    i_pop_id integer,
    i_routing_attempt integer,
    i_is_last_cdr boolean,
    i_lega_transport_protocol_id smallint,
    i_lega_local_ip character varying,
    i_lega_local_port integer,
    i_lega_remote_ip character varying,
    i_lega_remote_port integer,
    i_legb_transport_protocol_id smallint,
    i_legb_local_ip character varying,
    i_legb_local_port integer,
    i_legb_remote_ip character varying,
    i_legb_remote_port integer,
    i_time_data json,
    i_early_media_present boolean,
    i_legb_disconnect_code integer,
    i_legb_disconnect_reason character varying,
    i_disconnect_initiator integer,
    i_internal_disconnect_code integer,
    i_internal_disconnect_reason character varying,
    i_lega_disconnect_code integer,
    i_lega_disconnect_reason character varying,
    i_orig_call_id character varying,
    i_term_call_id character varying,
    i_local_tag character varying,
    i_msg_logger_path character varying,
    i_dump_level_id integer,
    i_audio_recorded boolean,
    i_rtp_stats_data json,
    i_global_tag character varying,
    i_resources character varying,
    i_active_resources json,
    i_failed_resource_type_id smallint,
    i_failed_resource_id bigint,
    i_dtmf_events json,
    i_versions json,
    i_is_redirected boolean,
    i_dynamic json
)
  RETURNS integer AS
$BODY$
DECLARE
  v_cdr cdr.cdr%rowtype;
  v_billing_event billing.cdr_v2;

  v_rtp_stats_data switch.rtp_stats_data_ty;
  v_time_data switch.time_data_ty;
  v_version_data switch.versions_ty;
  v_dynamic switch.dynamic_cdr_data_ty;

  v_nozerolen boolean;
BEGIN
  --  raise warning 'type: % id: %', i_failed_resource_type_id, i_failed_resource_id;
  --  RAISE warning 'DTMF: %', i_dtmf_events;

  v_time_data:=json_populate_record(null::switch.time_data_ty, i_time_data);
  v_version_data:=json_populate_record(null::switch.versions_ty, i_versions);
  v_dynamic:=json_populate_record(null::switch.dynamic_cdr_data_ty, i_dynamic);

  v_cdr.core_version=v_version_data.core;
  v_cdr.yeti_version=v_version_data.yeti;
  v_cdr.lega_user_agent=v_version_data.aleg;
  v_cdr.legb_user_agent=v_version_data.bleg;

  v_cdr.pop_id=i_pop_id;
  v_cdr.node_id=i_node_id;

  v_cdr.src_name_in:=v_dynamic.src_name_in;
  v_cdr.src_name_out:=v_dynamic.src_name_out;

  v_cdr.diversion_in:=v_dynamic.diversion_in;
  v_cdr.diversion_out:=v_dynamic.diversion_out;

  v_cdr.customer_id:=v_dynamic.customer_id;
  v_cdr.customer_external_id:=v_dynamic.customer_external_id;

  v_cdr.customer_acc_id:=v_dynamic.customer_acc_id;
  v_cdr.customer_account_check_balance=v_dynamic.customer_acc_check_balance;
  v_cdr.customer_acc_external_id=v_dynamic.customer_acc_external_id;
  v_cdr.customer_acc_vat:=v_dynamic.customer_acc_vat;

  v_cdr.customer_auth_id:=v_dynamic.customer_auth_id;
  v_cdr.customer_auth_external_id:=v_dynamic.customer_auth_external_id;
  v_cdr.customer_auth_name:=v_dynamic.customer_auth_name;

  v_cdr.vendor_id:=v_dynamic.vendor_id;
  v_cdr.vendor_external_id:=v_dynamic.vendor_external_id;
  v_cdr.vendor_id:=v_dynamic.vendor_acc_id;
  v_cdr.vendor_acc_external_id:=v_dynamic.vendor_acc_external_id;

  v_cdr.destination_id:=v_dynamic.destination_id;
  v_cdr.destination_prefix:=v_dynamic.destination_prefix;
  v_cdr.dialpeer_id:=v_dynamic.dialpeer_id;
  v_cdr.dialpeer_prefix:=v_dynamic.dialpeer_prefix;

  v_cdr.orig_gw_id:=v_dynamic.orig_gw_id;
  v_cdr.orig_gw_external_id:=v_dynamic.orig_gw_external_id;
  v_cdr.term_gw_id:=v_dynamic.term_gw_id;
  v_cdr.term_gw_external_id:=v_dynamic.term_gw_external_id;

  v_cdr.routing_group_id:=v_dynamic.routing_group_id;
  v_cdr.rateplan_id:=v_dynamic.rateplan_id;

  v_cdr.routing_attempt=i_routing_attempt;
  v_cdr.is_last_cdr=i_is_last_cdr;

  v_cdr.destination_initial_rate:=v_dynamic.destination_initial_rate::numeric;
  v_cdr.destination_next_rate:=v_dynamic.destination_next_rate::numeric;
  v_cdr.destination_initial_interval:=v_dynamic.destination_initial_interval;
  v_cdr.destination_next_interval:=v_dynamic.destination_next_interval;
  v_cdr.destination_fee:=v_dynamic.destination_fee;
  v_cdr.destination_rate_policy_id:=v_dynamic.destination_rate_policy_id;
  v_cdr.destination_reverse_billing=v_dynamic.destination_reverse_billing;

  v_cdr.dialpeer_initial_rate:=v_dynamic.dialpeer_initial_rate::numeric;
  v_cdr.dialpeer_next_rate:=v_dynamic.dialpeer_next_rate::numeric;
  v_cdr.dialpeer_initial_interval:=v_dynamic.dialpeer_initial_interval;
  v_cdr.dialpeer_next_interval:=v_dynamic.dialpeer_next_interval;
  v_cdr.dialpeer_fee:=v_dynamic.dialpeer_fee;
  v_cdr.dialpeer_reverse_billing=v_dynamic.dialpeer_reverse_billing;

  /* sockets addresses */
  v_cdr.sign_orig_transport_protocol_id=i_lega_transport_protocol_id;
  v_cdr.sign_orig_ip:=i_legA_remote_ip;
  v_cdr.sign_orig_port:=NULLIF(i_legA_remote_port,0);

  v_cdr.sign_orig_local_ip:=i_legA_local_ip;
  v_cdr.sign_orig_local_port=NULLIF(i_legA_local_port,0);

  v_cdr.sign_term_transport_protocol_id=i_legb_transport_protocol_id;
  v_cdr.sign_term_ip:=i_legB_remote_ip;
  v_cdr.sign_term_port:=NULLIF(i_legB_remote_port,0);

  v_cdr.sign_term_local_ip:=i_legB_local_ip;
  v_cdr.sign_term_local_port:=NULLIF(i_legB_remote_port,0);


  v_cdr.local_tag=i_local_tag;

  v_cdr.is_redirected=i_is_redirected;

  /* Call time data */
  v_cdr.time_start:=to_timestamp(v_time_data.time_start);
  v_cdr.time_limit:=v_time_data.time_limit;

  if v_time_data.time_connect is not null then
    v_cdr.time_connect:=to_timestamp(v_time_data.time_connect);
    v_cdr.duration:=switch.round(v_time_data.time_end-v_time_data.time_connect); -- rounding
    v_nozerolen:=true;
    v_cdr.success=true;
  else
    v_cdr.time_connect:=NULL;
    v_cdr.duration:=0;
    v_nozerolen:=false;
    v_cdr.success=false;
  end if;
  v_cdr.routing_delay=(v_time_data.leg_b_time-v_time_data.time_start)::real;
  v_cdr.pdd=(coalesce(v_time_data.time_18x,v_time_data.time_connect)-v_time_data.time_start)::real;
  v_cdr.rtt=(coalesce(v_time_data.time_1xx,v_time_data.time_18x,v_time_data.time_connect)-v_time_data.leg_b_time)::real;
  v_cdr.early_media_present=i_early_media_present;

  v_cdr.time_end:=to_timestamp(v_time_data.time_end);

  -- DC processing
  v_cdr.legb_disconnect_code:=i_legb_disconnect_code;
  v_cdr.legb_disconnect_reason:=i_legb_disconnect_reason;
  v_cdr.disconnect_initiator_id:=i_disconnect_initiator;
  v_cdr.internal_disconnect_code:=i_internal_disconnect_code;
  v_cdr.internal_disconnect_reason:=i_internal_disconnect_reason;
  v_cdr.lega_disconnect_code:=i_lega_disconnect_code;
  v_cdr.lega_disconnect_reason:=i_lega_disconnect_reason;

  v_cdr.src_prefix_in:=v_dynamic.src_prefix_in;
  v_cdr.src_prefix_out:=v_dynamic.src_prefix_out;
  v_cdr.dst_prefix_in:=v_dynamic.dst_prefix_in;
  v_cdr.dst_prefix_out:=v_dynamic.dst_prefix_out;

  v_cdr.orig_call_id=i_orig_call_id;
  v_cdr.term_call_id=i_term_call_id;

  /* removed */
  --v_cdr.dump_file:=i_msg_logger_path;

  v_cdr.dump_level_id:=i_dump_level_id;
  v_cdr.audio_recorded:=i_audio_recorded;

  v_cdr.auth_orig_transport_protocol_id=v_dynamic.auth_orig_protocol_id;
  v_cdr.auth_orig_ip:=v_dynamic.auth_orig_ip;
  v_cdr.auth_orig_ip:=v_dynamic.auth_orig_ip;
  v_cdr.auth_orig_port:=v_dynamic.auth_orig_port;


  v_rtp_stats_data:=json_populate_record(null::switch.rtp_stats_data_ty, i_rtp_stats_data);

  v_cdr.lega_rx_payloads:=v_rtp_stats_data.lega_rx_payloads;
  v_cdr.lega_tx_payloads:=v_rtp_stats_data.lega_tx_payloads;
  v_cdr.legb_rx_payloads:=v_rtp_stats_data.legb_rx_payloads;
  v_cdr.legb_tx_payloads:=v_rtp_stats_data.legb_tx_payloads;

  v_cdr.lega_rx_bytes:=v_rtp_stats_data.lega_rx_bytes;
  v_cdr.lega_tx_bytes:=v_rtp_stats_data.lega_tx_bytes;
  v_cdr.legb_rx_bytes:=v_rtp_stats_data.legb_rx_bytes;
  v_cdr.legb_tx_bytes:=v_rtp_stats_data.legb_tx_bytes;

  v_cdr.lega_rx_decode_errs:=v_rtp_stats_data.lega_rx_decode_errs;
  v_cdr.lega_rx_no_buf_errs:=v_rtp_stats_data.lega_rx_no_buf_errs;
  v_cdr.lega_rx_parse_errs:=v_rtp_stats_data.lega_rx_parse_errs;
  v_cdr.legb_rx_decode_errs:=v_rtp_stats_data.legb_rx_decode_errs;
  v_cdr.legb_rx_no_buf_errs:=v_rtp_stats_data.legb_rx_no_buf_errs;
  v_cdr.legb_rx_parse_errs:=v_rtp_stats_data.legb_rx_parse_errs;

  v_cdr.global_tag=i_global_tag;

  v_cdr.dst_country_id=v_dynamic.dst_country_id;
  v_cdr.dst_network_id=v_dynamic.dst_network_id;
  v_cdr.dst_prefix_routing=v_dynamic.dst_prefix_routing;
  v_cdr.src_prefix_routing=v_dynamic.src_prefix_routing;
  v_cdr.routing_plan_id=v_dynamic.routing_plan_id;
  v_cdr.lrn=v_dynamic.lrn;
  v_cdr.lnp_database_id=v_dynamic.lnp_database_id;

  v_cdr.ruri_domain=v_dynamic.ruri_domain;
  v_cdr.to_domain=v_dynamic.to_domain;
  v_cdr.from_domain=v_dynamic.from_domain;

  v_cdr.src_area_id=v_dynamic.src_area_id;
  v_cdr.dst_area_id=v_dynamic.dst_area_id;
  v_cdr.routing_tag_ids=v_dynamic.routing_tag_ids;


  v_cdr.id:=nextval('cdr.cdr_id_seq'::regclass);
  v_cdr.uuid:=public.uuid_generate_v1();

  v_cdr.pai_in=v_dynamic.pai_in;
  v_cdr.ppi_in=v_dynamic.ppi_in;
  v_cdr.privacy_in=v_dynamic.privacy_in;
  v_cdr.rpid_in=v_dynamic.rpid_in;
  v_cdr.rpid_privacy_in=v_dynamic.rpid_privacy_in;
  v_cdr.pai_out=v_dynamic.pai_out;
  v_cdr.ppi_out=v_dynamic.ppi_out;
  v_cdr.privacy_out=v_dynamic.privacy_out;
  v_cdr.rpid_out=v_dynamic.rpid_out;
  v_cdr.rpid_privacy_out=v_dynamic.rpid_privacy_out;


  v_cdr:=billing.bill_cdr(v_cdr);

  perform stats.update_rt_stats(v_cdr);

  v_billing_event.id=v_cdr.id;
  v_billing_event.customer_id=v_cdr.customer_id;
  v_billing_event.vendor_id=v_cdr.vendor_id;
  v_billing_event.customer_acc_id=v_cdr.customer_acc_id;
  v_billing_event.vendor_acc_id=v_cdr.vendor_acc_id;
  v_billing_event.customer_auth_id=v_cdr.customer_auth_id;
  v_billing_event.destination_id=v_cdr.destination_id;
  v_billing_event.dialpeer_id=v_cdr.dialpeer_id;
  v_billing_event.orig_gw_id=v_cdr.orig_gw_id;
  v_billing_event.term_gw_id=v_cdr.term_gw_id;
  v_billing_event.routing_group_id=v_cdr.routing_group_id;
  v_billing_event.rateplan_id=v_cdr.rateplan_id;

  v_billing_event.destination_next_rate=v_cdr.destination_next_rate;
  v_billing_event.destination_fee=v_cdr.destination_fee;
  v_billing_event.destination_initial_interval=v_cdr.destination_initial_interval;
  v_billing_event.destination_next_interval=v_cdr.destination_next_interval;
  v_billing_event.destination_initial_rate=v_cdr.destination_initial_rate;
  v_billing_event.destination_reverse_billing=v_cdr.destination_reverse_billing;

  v_billing_event.dialpeer_next_rate=v_cdr.dialpeer_next_rate;
  v_billing_event.dialpeer_fee=v_cdr.dialpeer_fee;
  v_billing_event.dialpeer_reverse_billing=v_cdr.dialpeer_reverse_billing;

  v_billing_event.internal_disconnect_code=v_cdr.internal_disconnect_code;
  v_billing_event.internal_disconnect_reason=v_cdr.internal_disconnect_reason;
  v_billing_event.disconnect_initiator_id=v_cdr.disconnect_initiator_id;
  v_billing_event.customer_price=v_cdr.customer_price;
  v_billing_event.vendor_price=v_cdr.vendor_price;
  v_billing_event.duration=v_cdr.duration;
  v_billing_event.success=v_cdr.success;
  v_billing_event.profit=v_cdr.profit;
  v_billing_event.time_start=v_cdr.time_start;
  v_billing_event.time_connect=v_cdr.time_connect;
  v_billing_event.time_end=v_cdr.time_end;
  v_billing_event.lega_disconnect_code=v_cdr.lega_disconnect_code;
  v_billing_event.lega_disconnect_reason=v_cdr.lega_disconnect_reason;
  v_billing_event.legb_disconnect_code=v_cdr.legb_disconnect_code;
  v_billing_event.legb_disconnect_reason=v_cdr.legb_disconnect_reason;
  v_billing_event.src_prefix_in=v_cdr.src_prefix_in;
  v_billing_event.src_prefix_out=v_cdr.src_prefix_out;
  v_billing_event.dst_prefix_in=v_cdr.dst_prefix_in;
  v_billing_event.dst_prefix_out=v_cdr.dst_prefix_out;
  v_billing_event.orig_call_id=v_cdr.orig_call_id;
  v_billing_event.term_call_id=v_cdr.term_call_id;
  v_billing_event.local_tag=v_cdr.local_tag;
  v_billing_event.from_domain=v_cdr.from_domain;

  -- generate event to routing engine
  perform event.billing_insert_event('cdr_full',v_billing_event);
  INSERT INTO cdr.cdr VALUES( v_cdr.*);
  RETURN 0;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 10;


alter type billing.interval_billing_data add attribute amount_no_vat numeric;

CREATE OR REPLACE FUNCTION billing.interval_billing(
    i_duration numeric,
    i_connection_fee numeric,
    i_initial_rate numeric,
    i_next_rate numeric,
    i_initial_interval numeric,
    i_next_interval numeric,
    i_vat numeric DEFAULT 0)
  RETURNS billing.interval_billing_data AS
$BODY$
DECLARE
    _v billing.interval_billing_data%rowtype;
BEGIN
    i_vat=COALESCE(i_vat,0);
    _v.amount_no_vat=i_connection_fee+
            i_initial_interval*i_initial_rate::numeric/60 + -- initial interval billing
            (i_duration>i_initial_interval)::boolean::integer * -- next interval billing enabled
            CEIL((i_duration-i_initial_interval)::numeric/i_next_interval) *-- next interval count
            i_next_interval * --interval len
            i_next_rate::numeric/60; -- next interval rate per second

    _v.amount=_v.amount_no_vat*(1+i_vat/100);

    _v.duration=i_initial_interval+(i_duration>i_initial_interval)::boolean::integer * CEIL((i_duration-i_initial_interval)::numeric/i_next_interval) *i_next_interval;

    RETURN _v;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 10;


CREATE OR REPLACE FUNCTION billing.bill_cdr(i_cdr cdr.cdr)
  RETURNS cdr.cdr AS
$BODY$
DECLARE
    _v billing.interval_billing_data%rowtype;
BEGIN
    if i_cdr.duration>0 and i_cdr.success then  -- run billing.
        _v=billing.interval_billing(
            i_cdr.duration,
            i_cdr.destination_fee,
            i_cdr.destination_initial_rate,
            i_cdr.destination_next_rate,
            i_cdr.destination_initial_interval,
            i_cdr.destination_next_interval,
            i_cdr.customer_acc_vat);
         i_cdr.customer_price=_v.amount;
         i_cdr.customer_price_no_vat=_v.amount_no_vat;
         i_cdr.customer_duration=_v.duration;

         _v=billing.interval_billing(
            i_cdr.duration,
            i_cdr.dialpeer_fee,
            i_cdr.dialpeer_initial_rate,
            i_cdr.dialpeer_next_rate,
            i_cdr.dialpeer_initial_interval,
            i_cdr.dialpeer_next_interval,
            0);
         i_cdr.vendor_price=_v.amount;
         i_cdr.vendor_duration=_v.duration;
         i_cdr.profit=i_cdr.customer_price-i_cdr.vendor_price;
    else
        i_cdr.customer_price=0;
        i_cdr.vendor_price=0;
        i_cdr.profit=0;
    end if;
    RETURN i_cdr;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 10;



    }
  end

  def down
    execute %q{

CREATE OR REPLACE FUNCTION billing.interval_billing(
    i_duration numeric,
    i_connection_fee numeric,
    i_initial_rate numeric,
    i_next_rate numeric,
    i_initial_interval numeric,
    i_next_interval numeric,
    i_vat numeric DEFAULT 0)
  RETURNS billing.interval_billing_data AS
$BODY$
DECLARE
    _v billing.interval_billing_data%rowtype;
BEGIN
    i_vat=COALESCE(i_vat,0);
    _v.amount=i_connection_fee+
            i_initial_interval*i_initial_rate::numeric/60 + -- initial interval billing
            (i_duration>i_initial_interval)::boolean::integer * -- next interval billing enabled
            CEIL((i_duration-i_initial_interval)::numeric/i_next_interval) *-- next interval count
            i_next_interval * --interval len
            i_next_rate::numeric/60; -- next interval rate per second

    _v.duration=i_initial_interval+(i_duration>i_initial_interval)::boolean::integer * CEIL((i_duration-i_initial_interval)::numeric/i_next_interval) *i_next_interval;

    RETURN _v;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 10;

CREATE OR REPLACE FUNCTION billing.bill_cdr(i_cdr cdr.cdr)
  RETURNS cdr.cdr AS
$BODY$
DECLARE
    _v billing.interval_billing_data%rowtype;
BEGIN
    if i_cdr.duration>0 and i_cdr.success then  -- run billing.
        _v=billing.interval_billing(
            i_cdr.duration,
            i_cdr.destination_fee,
            i_cdr.destination_initial_rate,
            i_cdr.destination_next_rate,
            i_cdr.destination_initial_interval,
            i_cdr.destination_next_interval,
            0);
         i_cdr.customer_price=_v.amount;

         _v=billing.interval_billing(
            i_cdr.duration,
            i_cdr.dialpeer_fee,
            i_cdr.dialpeer_initial_rate,
            i_cdr.dialpeer_next_rate,
            i_cdr.dialpeer_initial_interval,
            i_cdr.dialpeer_next_interval,
            0);
         i_cdr.vendor_price=_v.amount;
         i_cdr.profit=i_cdr.customer_price-i_cdr.vendor_price;
    else
        i_cdr.customer_price=0;
        i_cdr.vendor_price=0;
        i_cdr.profit=0;
    end if;
    RETURN i_cdr;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 10;

      drop type switch.dynamic_cdr_data_ty;
      drop FUNCTION switch.writecdr(
    i_is_master boolean,
    i_node_id integer,
    i_pop_id integer,
    i_routing_attempt integer,
    i_is_last_cdr boolean,
    i_lega_transport_protocol_id smallint,
    i_lega_local_ip character varying,
    i_lega_local_port integer,
    i_lega_remote_ip character varying,
    i_lega_remote_port integer,
    i_legb_transport_protocol_id smallint,
    i_legb_local_ip character varying,
    i_legb_local_port integer,
    i_legb_remote_ip character varying,
    i_legb_remote_port integer,
    i_time_data json,
    i_early_media_present boolean,
    i_legb_disconnect_code integer,
    i_legb_disconnect_reason character varying,
    i_disconnect_initiator integer,
    i_internal_disconnect_code integer,
    i_internal_disconnect_reason character varying,
    i_lega_disconnect_code integer,
    i_lega_disconnect_reason character varying,
    i_orig_call_id character varying,
    i_term_call_id character varying,
    i_local_tag character varying,
    i_msg_logger_path character varying,
    i_dump_level_id integer,
    i_audio_recorded boolean,
    i_rtp_stats_data json,
    i_global_tag character varying,
    i_resources character varying,
    i_active_resources json,
    i_failed_resource_type_id smallint,
    i_failed_resource_id bigint,
    i_dtmf_events json,
    i_versions json,
    i_is_redirected boolean,
    i_dynamic json );


  alter type billing.interval_billing_data drop attribute amount_no_vat;

  alter table cdr.cdr drop column customer_external_id;
  alter table cdr.cdr drop column customer_auth_external_id;
  alter table cdr.cdr drop column customer_acc_vat;
  alter table cdr.cdr drop column customer_acc_external_id;
  alter table cdr.cdr drop column routing_tag_ids;
  alter table cdr.cdr drop column vendor_external_id;
  alter table cdr.cdr drop column vendor_acc_external_id;
  alter table cdr.cdr drop column orig_gw_external_id;
  alter table cdr.cdr drop column term_gw_external_id;
  alter table cdr.cdr drop column failed_resource_type_id;
  alter table cdr.cdr drop column failed_resource_id;
  alter table cdr.cdr drop column customer_price_no_vat;
  alter table cdr.cdr drop column customer_duration;
  alter table cdr.cdr drop column vendor_duration;

  alter table cdr.cdr_archive drop column customer_external_id;
  alter table cdr.cdr_archive drop column customer_auth_external_id;
  alter table cdr.cdr_archive drop column customer_acc_vat;
  alter table cdr.cdr_archive drop column customer_acc_external_id;
  alter table cdr.cdr_archive drop column routing_tag_ids;
  alter table cdr.cdr_archive drop column vendor_external_id;
  alter table cdr.cdr_archive drop column vendor_acc_external_id;
  alter table cdr.cdr_archive drop column orig_gw_external_id;
  alter table cdr.cdr_archive drop column term_gw_external_id;
  alter table cdr.cdr_archive drop column failed_resource_type_id;
  alter table cdr.cdr_archive drop column failed_resource_id;
  alter table cdr.cdr_archive drop column customer_price_no_vat;
  alter table cdr.cdr_archive drop column customer_duration;
  alter table cdr.cdr_archive drop column vendor_duration;

    }
  end
end
