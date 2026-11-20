-- Generated from sdk/bindings/rac1.json by sdk/tools/gen_binding.py. Do not edit.
-- SPDX-License-Identifier: MIT
--
-- The `openrac` global as a script mod for rac1 sees it (docs/port/MODS.md, section 11): put this
-- file where your editor's Luau language server reads definitions (luau-lsp: --definitions).
-- A hook point is named by its permanent id (rac1.player.turn_to_heading) or one of its aliases.
-- EXPERIMENTAL: the rac1.moby.* hook points and openrac.pvars come from the behaviour catalogue,
-- whose names may still change; their ids do not.

type HookPoint =
      "rac1.moby.item_offer.update"
    | "rac1.omni.weapon.ryno.fire"
    | "rac1.omni.moby.delete"
    | "rac1.pad.process_report"
    | "rac1.player.update_motion_input"
    | "rac1.player.turn_to_heading"
    | "rac1.player.set_planar_velocity"
    | "rac1.camera.follow.apply_overrides"
    | "rac1.player.advance_animation"
    | "rac1.player.update"
    | "rac1.item.give"
    | "rac1.planet.unlock"
    | "rac1.help.request"
    | "rac1.ship.init_transition"
    | "rac1.vendor.init_level_stock"
    | "rac1.vendor.build_item_list"
    | "rac1.gold_bolt.count_collected"
    | "rac1.player.take_damage"
    | "rac1.combat.get_hit"
    | "rac1.weapon.take_ammo"
    | "rac1.weapon.blaster.pick_target"
    | "rac1.weapon.ryno.pick_target"
    | "rac1.weapon.gold_devastator.pick_target"
    | "rac1.weapon.drone.pick_target"
    | "rac1.moby.record_death"
    | "rac1.level.load_gameplay"
    | "rac1.player.approach_speed"
    | "rac1.ship.travel_to"
    | "rac1.moby.collect_bolt"
    | "rac1.menu.item_grid.update"
    | "rac1.menu.item_grid.draw"
    | "rac1.menu.item_slots.update"
    | "rac1.menu.quick_select.draw"
    | "rac1.menu.quick_select.load"
    | "rac1.menu.quick_select.store"
    | "rac1.menu.item_text.draw"
    | "rac1.menu.item_ammo.draw"
    | "rac1.menu.preview.bind"
    | "rac1.menu.preview.update"
    | "rac1.menu.preview.draw_available"
    | "rac1.menu.preview.draw_selected"
    | "rac1.menu.equipped_preview.update"
    | "rac1.menu.equipped_preview.draw"
    | "rac1.hud.quick_select.init"
    | "rac1.hud.quick_select.update"
    | "rac1.hud.quick_select.draw"
    | "rac1.vendor.menu_update"
    | "rac1.vendor.initialize_selected"
    | "rac1.ammo.choose_drop"
    | "rac1.ammo.spawn_drop"
    | "rac1.save.prepare"
    | "rac1.save.request_autosave"
    | "rac1.save.restore"
    | "rac1.save.restore_data"
    | "rac1.save.new_game"
    | "rac1.save.new_game_plus"
    | "rac1.save.serialize"
    | "rac1.save.update_state"
    | "rac1.text.msg_string"
    | "rac1.vendor.open_menu"
    | "rac1.gold_bolt.count_unspent"
    | "rac1.omni.damage.build_hit"
    | "rac1.omni.damage.hit_victim"
    | "rac1.omni.wrench.swing"
    | "rac1.omni.wrench.throw"
    | "rac1.moby.wrench.update"
    | "rac1.moby.suck_cannon.update"
    | "rac1.moby.moby192.update"
    | "rac1.omni.weapon.devastator.update"
    | "rac1.moby.moby163.update"
    | "rac1.moby.moby175.update"
    | "rac1.omni.weapon.blaster.update"
    | "rac1.moby.pyrocitor.update"
    | "rac1.moby.mine_glove.update"
    | "rac1.moby.moby180.update"
    | "rac1.omni.weapon.tesla_claw.update"
    | "rac1.moby.carrier.update"
    | "rac1.moby.morphoray.update"
    | "rac1.moby.ryno.update"
    | "rac1.moby.decoy_glove.update"
    | "rac1.moby.ammo_pickup.update"
    | "rac1.omni.ammo.add"
    | "rac1.omni.weapon.select"
    | "rac1.omni.damage.resolve"
    | "rac1.omni.weapon.flame.create"
    | "rac1.omni.weapon.bomb_glove.fire"
    | "rac1.omni.weapon.mine_glove.fire"
    | "rac1.omni.weapon.glove_of_doom.fire"
    | "rac1.omni.weapon.devastator.fire"
    | "rac1.omni.weapon.visibomb.fire"
    | "rac1.omni.weapon.blaster.fire"
    | "rac1.omni.moby.create"
    | "rac1.moby.hero_bomb.update"
    | "rac1.moby.mine.update"
    | "rac1.moby.moby305.update"
    | "rac1.moby.rocket_steer.update"
    | "rac1.moby.doom_bot.update"
    | "rac1.moby.bomb_230.update"
    | "rac1.moby.visibomb_missile.update"
    | "rac1.moby.missile.update"
    | "rac1.omni.collide.segment"
    | "rac1.omni.collide.sphere_mobys"
    | "rac1.omni.blast.apply"
    | "rac1.omni.hero.items_attach"
    | "rac1.omni.ammo.collect"
    | "rac1.omni.hud.health_draw"
    | "rac1.moby.class_1750.update"
    | "rac1.moby.class_676.update"
    | "rac1.moby.class_482.update"
    | "rac1.moby.texture_scroll.update"
    | "rac1.moby.camera_object.update"
    | "rac1.moby.light_beam.update"
    | "rac1.moby.bolt.update"
    | "rac1.moby.spin_fade_out.update"
    | "rac1.moby.falling_spark.update"
    | "rac1.moby.debris_bounce.update"
    | "rac1.moby.moby166.update"
    | "rac1.moby.moby167.update"
    | "rac1.moby.moby179.update"
    | "rac1.moby.moby188.update"
    | "rac1.moby.thrown_object.update"
    | "rac1.moby.moby209.update"
    | "rac1.moby.morphoray_chicken.update"
    | "rac1.moby.moby428.update"
    | "rac1.moby.drone.update"
    | "rac1.moby.crate.update"
    | "rac1.moby.veldin_ship.update"
    | "rac1.moby.target_tracker.update"
    | "rac1.moby.clank_pack.update"
    | "rac1.moby.moby639.update"
    | "rac1.moby.horny_toad.update"
    | "rac1.moby.infobot.update"
    | "rac1.moby.particle_field.update"
    | "rac1.moby.grow_and_fade_out.update"
    | "rac1.moby.trail_moby.update"
    | "rac1.moby.nanotech_ball.update"
    | "rac1.moby.moby834.update"
    | "rac1.moby.pulsing_color_moby.update"
    | "rac1.moby.quad_moby.update"
    | "rac1.moby.moby1143.update"
    | "rac1.moby.hydrodisplacer_pad.update"
    | "rac1.moby.moby1290.update"
    | "rac1.moby.moby1413.update"
    | "rac1.moby.vendor.update"
    | "rac1.moby.beam_slot_manager.update"
    | "rac1.moby.moby1545.update"
    | "rac1.moby.path_follow_moby.update"
    | "rac1.moby.grass.update"
    | "rac1.moby.fx_group.update"
    | "rac1.moby.path_platform.update"
    | "rac1.moby.particle_emitter.update"
    | "rac1.moby.moby156.update"
    | "rac1.moby.bolt_crank.update"
    | "rac1.moby.sand_mouse.update"
    | "rac1.moby.birdbot.update"
    | "rac1.moby.burning_debris.update"
    | "rac1.moby.amoeboid.update"
    | "rac1.moby.peckbot.update"
    | "rac1.moby.moby604.update"
    | "rac1.moby.moby605.update"
    | "rac1.moby.path_carrier.update"
    | "rac1.moby.crank_rotator.update"
    | "rac1.moby.tethered_mine.update"
    | "rac1.moby.crank_slider.update"
    | "rac1.moby.rider_carrier.update"
    | "rac1.moby.class_845.update"
    | "rac1.moby.scrolling_layers2.update"
    | "rac1.moby.grind_rail.update"
    | "rac1.moby.flying_burst.update"
    | "rac1.moby.gunship.update"
    | "rac1.moby.hover_enemy.update"
    | "rac1.moby.debris_moby.update"
    | "rac1.moby.steam_vent.update"
    | "rac1.moby.collapsing_platform.update"
    | "rac1.moby.lift_move.update"
    | "rac1.moby.breakable_rock.update"
    | "rac1.moby.oscillating_spinner.update"
    | "rac1.moby.projectile_breakable.update"
    | "rac1.moby.falling_drop.update"
    | "rac1.moby.breakable_wall.update"
    | "rac1.moby.agnogg_ship.update"
    | "rac1.moby.cutscene_trigger.update"
    | "rac1.moby.hinged_bridge.update"
    | "rac1.moby.water_surface_fx.update"
    | "rac1.moby.breakable_pot.update"
    | "rac1.moby.pulsing_mesh.update"
    | "rac1.moby.sliding_door.update"
    | "rac1.moby.talking_npc.update"
    | "rac1.moby.moby778.update"
    | "rac1.moby.smoke_emitter.update"
    | "rac1.moby.falling_chunk.update"
    | "rac1.moby.checkpoint_trigger.update"
    | "rac1.moby.enemy_spawner.update"
    | "rac1.moby.rc_range_limiter.update"
    | "rac1.moby.moby1042.update"
    | "rac1.moby.gold_bolt.update"
    | "rac1.moby.teleporter_pad.update"
    | "rac1.moby.moby1225.update"
    | "rac1.moby.help_hint_director.update"
    | "rac1.moby.wandering_light.update"
    | "rac1.moby.moby1510.update"
    | "rac1.moby.moby1546.update"
    | "rac1.moby.class_1633.update"
    | "rac1.moby.moby1813.update"
    | "rac1.moby.mouse_critter.update"
    | "rac1.moby.moby1848.update"
    | "rac1.moby.trackdrive_left.update"
    | "rac1.moby.sand_shark.update"
    | "rac1.moby.moby612.update"
    | "rac1.moby.trespasser_puzzle.update"
    | "rac1.moby.elevator_651.update"
    | "rac1.moby.pusher.update"
    | "rac1.moby.moby656.update"
    | "rac1.moby.sand_shark_nest.update"
    | "rac1.moby.moby675.update"
    | "rac1.moby.rotate_platform.update"
    | "rac1.moby.moby713.update"
    | "rac1.moby.moby732.update"
    | "rac1.moby.rocket_launcher.update"
    | "rac1.moby.rocket_door1.update"
    | "rac1.moby.moby743.update"
    | "rac1.moby.moby744.update"
    | "rac1.moby.moby755.update"
    | "rac1.moby.hideable_flower.update"
    | "rac1.moby.moby762.update"
    | "rac1.moby.skids_agent.update"
    | "rac1.moby.skid_mc_marx_aridia.update"
    | "rac1.moby.driver_lift.update"
    | "rac1.moby.moby854.update"
    | "rac1.moby.moby1005.update"
    | "rac1.moby.shard_debris.update"
    | "rac1.moby.background_ship.update"
    | "rac1.moby.ship_path.update"
    | "rac1.moby.tutorial_hint.update"
    | "rac1.moby.moby1479.update"
    | "rac1.moby.break_on_hit_l02.update"
    | "rac1.moby.metropolis_train.update"
    | "rac1.moby.moving_platform.update"
    | "rac1.moby.metropolis_train_carriage.update"
    | "rac1.moby.train_car.update"
    | "rac1.moby.parent_follow_fade.update"
    | "rac1.moby.child_spawner.update"
    | "rac1.moby.moby545.update"
    | "rac1.moby.moby573.update"
    | "rac1.moby.moby574.update"
    | "rac1.moby.trooper.update"
    | "rac1.moby.kerwan_mine.update"
    | "rac1.moby.helicopter_gunship.update"
    | "rac1.moby.rail_taxi.update"
    | "rac1.moby.moby817.update"
    | "rac1.moby.spinner.update"
    | "rac1.moby.kerwan_homing_rocket.update"
    | "rac1.moby.moby848.update"
    | "rac1.moby.quest_giver.update"
    | "rac1.moby.rail_moby.update"
    | "rac1.moby.rail_spawner.update"
    | "rac1.moby.guide.update"
    | "rac1.moby.moby914.update"
    | "rac1.moby.fred_1.update"
    | "rac1.moby.qwark_watch.update"
    | "rac1.moby.ambient_stream_l03.update"
    | "rac1.moby.rise_when_collected.update"
    | "rac1.moby.rail_lift.update"
    | "rac1.moby.falling_moby.update"
    | "rac1.moby.tutorial_hint_trigger.update"
    | "rac1.moby.cutscene_beams.update"
    | "rac1.moby.swarm.update"
    | "rac1.moby.class_161.update"
    | "rac1.moby.moby184_shot.update"
    | "rac1.moby.big_axebot.update"
    | "rac1.moby.circular_saw.update"
    | "rac1.moby.blarg_trooper.update"
    | "rac1.moby.switch_follower.update"
    | "rac1.moby.lever_door.update"
    | "rac1.moby.path_vehicle.update"
    | "rac1.moby.floating_platform_481.update"
    | "rac1.moby.delete_moby.update"
    | "rac1.moby.wb_moby.update"
    | "rac1.moby.moby584.update"
    | "rac1.moby.path_keyframe_blend.update"
    | "rac1.moby.drift_spark_moby.update"
    | "rac1.moby.collectable.update"
    | "rac1.moby.warp_portal.update"
    | "rac1.moby.unlock_planet_pad.update"
    | "rac1.moby.moby1343.update"
    | "rac1.moby.bouncing_debris.update"
    | "rac1.moby.sparks_trigger_l04.update"
    | "rac1.moby.sharkigator_35.update"
    | "rac1.moby.scenery_ship.update"
    | "rac1.moby.grazing_critter.update"
    | "rac1.moby.moby258.update"
    | "rac1.moby.moby341.update"
    | "rac1.moby.hoverboard.update"
    | "rac1.moby.extermibot.update"
    | "rac1.moby.extermitank.update"
    | "rac1.moby.skid_mc_marx.update"
    | "rac1.moby.floating_platform_810.update"
    | "rac1.moby.moby812.update"
    | "rac1.moby.moby823.update"
    | "rac1.moby.floor_button.update"
    | "rac1.moby.water_surface.update"
    | "rac1.moby.electric_gate.update"
    | "rac1.moby.fog_zone.update"
    | "rac1.moby.pose_slide_out.update"
    | "rac1.moby.drain_cover.update"
    | "rac1.moby.pipe_mounted_grating.update"
    | "rac1.moby.gate_rise.update"
    | "rac1.moby.emitter_l05.update"
    | "rac1.moby.lift_l05.update"
    | "rac1.moby.pulsing_marker.update"
    | "rac1.moby.class_893.update"
    | "rac1.moby.triggered_rotor.update"
    | "rac1.moby.hoverboard_girl.update"
    | "rac1.moby.bouncer.update"
    | "rac1.moby.shady_salesman.update"
    | "rac1.moby.blarg_gun.update"
    | "rac1.moby.water_plane_marker.update"
    | "rac1.moby.bobbing_moby_l05.update"
    | "rac1.moby.pickup_l05.update"
    | "rac1.moby.qwarks_trailer.update"
    | "rac1.moby.moby1139.update"
    | "rac1.moby.challenge.update"
    | "rac1.moby.mine_moby.update"
    | "rac1.moby.moby1550.update"
    | "rac1.moby.orbiting_platform.update"
    | "rac1.moby.moby302.update"
    | "rac1.moby.moby303.update"
    | "rac1.moby.moby367.update"
    | "rac1.moby.frog.update"
    | "rac1.moby.gadgebot.update"
    | "rac1.moby.swinging_hazard.update"
    | "rac1.moby.door_ring.update"
    | "rac1.moby.drawbridge.update"
    | "rac1.moby.class_1035.update"
    | "rac1.moby.collectible_spawner.update"
    | "rac1.moby.trigger_lists.update"
    | "rac1.moby.moby1040.update"
    | "rac1.moby.moby1048.update"
    | "rac1.moby.alien_queen.update"
    | "rac1.moby.moby1054.update"
    | "rac1.moby.callable_lift.update"
    | "rac1.moby.class_1062.update"
    | "rac1.moby.launch_trigger.update"
    | "rac1.moby.moby1068.update"
    | "rac1.moby.camera_takeover_trigger.update"
    | "rac1.moby.spinning_debris.update"
    | "rac1.moby.bobbing_moby.update"
    | "rac1.moby.moby1105.update"
    | "rac1.moby.moby1108.update"
    | "rac1.moby.shuttle.update"
    | "rac1.moby.red_button.update"
    | "rac1.moby.moby1123.update"
    | "rac1.moby.moby1302.update"
    | "rac1.moby.class_1348.update"
    | "rac1.moby.spark_emitter.update"
    | "rac1.moby.sparks_trigger_l06.update"
    | "rac1.moby.spawn_child_and_delete.update"
    | "rac1.moby.break_on_hit_blarg.update"
    | "rac1.moby.moby1898.update"
    | "rac1.moby.taxi_platform_38.update"
    | "rac1.moby.taxi_platform_1474.update"
    | "rac1.moby.moby436.update"
    | "rac1.moby.ambient_stream_l07.update"
    | "rac1.moby.purple_ship_529.update"
    | "rac1.moby.path_train.update"
    | "rac1.moby.bolt_projectile.update"
    | "rac1.moby.gravity_debris.update"
    | "rac1.moby.timed_pad.update"
    | "rac1.moby.water_plate.update"
    | "rac1.moby.target_driven_slider.update"
    | "rac1.moby.audio_stream_trigger.update"
    | "rac1.moby.lobber_enemy.update"
    | "rac1.moby.shockwave.update"
    | "rac1.moby.lobbed_bomb.update"
    | "rac1.moby.sharkigator_1059.update"
    | "rac1.moby.door.update"
    | "rac1.moby.moby1069.update"
    | "rac1.moby.falling_leaf.update"
    | "rac1.moby.snagglebeast.update"
    | "rac1.moby.swooper.update"
    | "rac1.moby.breakable_prop.update"
    | "rac1.moby.machinegun_turret_1126.update"
    | "rac1.moby.moving_moby_l07.update"
    | "rac1.moby.bridge.update"
    | "rac1.moby.moby1133.update"
    | "rac1.moby.moby1142.update"
    | "rac1.moby.spark_burst_spawner.update"
    | "rac1.moby.moby1789.update"
    | "rac1.moby.moby152.update"
    | "rac1.moby.bomb_248.update"
    | "rac1.moby.scoutbot.update"
    | "rac1.moby.bomber_tank.update"
    | "rac1.moby.moby327.update"
    | "rac1.moby.blarg_bomb_thrower.update"
    | "rac1.moby.route_platform.update"
    | "rac1.moby.moby425.update"
    | "rac1.moby.guided_rocket.update"
    | "rac1.moby.moby438.update"
    | "rac1.moby.cannon.update"
    | "rac1.moby.falling_debris.update"
    | "rac1.moby.moby444.update"
    | "rac1.moby.batalia_bolt_thief.update"
    | "rac1.moby.moby458.update"
    | "rac1.moby.moby462.update"
    | "rac1.moby.swarm_leader.update"
    | "rac1.moby.group_clear.update"
    | "rac1.moby.gate_swing.update"
    | "rac1.moby.moby600.update"
    | "rac1.moby.moby621.update"
    | "rac1.moby.moby648.update"
    | "rac1.moby.flicker_light.update"
    | "rac1.moby.paratrooper.update"
    | "rac1.moby.commando.update"
    | "rac1.moby.deserter.update"
    | "rac1.moby.moby1283.update"
    | "rac1.moby.fire_bolt.update"
    | "rac1.moby.moby1349.update"
    | "rac1.moby.moby1400.update"
    | "rac1.moby.moby1553.update"
    | "rac1.moby.moby1629.update"
    | "rac1.moby.moby1641.update"
    | "rac1.moby.moby1649.update"
    | "rac1.moby.airship_part.update"
    | "rac1.moby.moby52.update"
    | "rac1.moby.ground_enemy.update"
    | "rac1.moby.asteroid_belt.update"
    | "rac1.moby.breakable_stack.update"
    | "rac1.moby.moby279.update"
    | "rac1.moby.tumbling_debris.update"
    | "rac1.moby.heavy_tumbling_debris.update"
    | "rac1.moby.moby417.update"
    | "rac1.moby.moby664.update"
    | "rac1.moby.moby1000.update"
    | "rac1.moby.path_platform_l09.update"
    | "rac1.moby.pressure_plate.update"
    | "rac1.moby.airship_chain_link.update"
    | "rac1.moby.mountable_turret.update"
    | "rac1.moby.moby1206.update"
    | "rac1.moby.enemy_shot.update"
    | "rac1.moby.barrier.update"
    | "rac1.moby.linked_riser.update"
    | "rac1.moby.moby1766.update"
    | "rac1.moby.moby1885.update"
    | "rac1.moby.moby1886.update"
    | "rac1.moby.moby1033.update"
    | "rac1.moby.bobbing_platform.update"
    | "rac1.moby.spinning_pickup.update"
    | "rac1.moby.moby22.update"
    | "rac1.moby.near_hero_sparkle.update"
    | "rac1.moby.moby702.update"
    | "rac1.moby.moby794.update"
    | "rac1.moby.moby819.update"
    | "rac1.moby.moby859.update"
    | "rac1.moby.moby938.update"
    | "rac1.moby.timed_shooter.update"
    | "rac1.moby.electric_spark.update"
    | "rac1.moby.height_glide.update"
    | "rac1.moby.moby1031.update"
    | "rac1.moby.moby1047.update"
    | "rac1.moby.sound_prop.update"
    | "rac1.moby.moby1090.update"
    | "rac1.moby.collectible_trigger.update"
    | "rac1.moby.moby1196.update"
    | "rac1.moby.moby1199.update"
    | "rac1.moby.toxic_crab.update"
    | "rac1.moby.blarg_ship.update"
    | "rac1.moby.exhaust_vent.update"
    | "rac1.moby.nanotech_vendor.update"
    | "rac1.moby.moby1344.update"
    | "rac1.moby.linked_turret.update"
    | "rac1.moby.moby1378.update"
    | "rac1.moby.swing_door.update"
    | "rac1.moby.moby1424.update"
    | "rac1.moby.effect_emitter.update"
    | "rac1.moby.moby1555.update"
    | "rac1.moby.moby1855.update"
    | "rac1.moby.moby1856.update"
    | "rac1.moby.pickup.update"
    | "rac1.moby.moby37.update"
    | "rac1.moby.moby65.update"
    | "rac1.moby.moby90.update"
    | "rac1.moby.moby114.update"
    | "rac1.moby.pokitaru_vendor.update"
    | "rac1.moby.moby318.update"
    | "rac1.moby.moby361.update"
    | "rac1.moby.class_1009.update"
    | "rac1.moby.fireball.update"
    | "rac1.moby.moby1034.update"
    | "rac1.moby.pokitaru_boat.update"
    | "rac1.moby.ocean.update"
    | "rac1.moby.cutscene_controller.update"
    | "rac1.moby.moby1157.update"
    | "rac1.moby.moby1158.update"
    | "rac1.moby.moby1159.update"
    | "rac1.moby.moby1178.update"
    | "rac1.moby.moby1179.update"
    | "rac1.moby.moby1180.update"
    | "rac1.moby.ship_collider.update"
    | "rac1.moby.moby1219.update"
    | "rac1.moby.psytcopus.update"
    | "rac1.moby.jet_fighter.update"
    | "rac1.moby.moby1246.update"
    | "rac1.moby.gate.update"
    | "rac1.moby.moby1264.update"
    | "rac1.moby.bubbling_vent.update"
    | "rac1.moby.moby1297.update"
    | "rac1.moby.flying_craft.update"
    | "rac1.moby.moby1350.update"
    | "rac1.moby.bubble.update"
    | "rac1.moby.pokitaru_surface_near.update"
    | "rac1.moby.pokitaru_surface_far.update"
    | "rac1.moby.moby19.update"
    | "rac1.moby.hoven_troll.update"
    | "rac1.moby.hoven_platform.update"
    | "rac1.moby.miner.update"
    | "rac1.moby.moby293.update"
    | "rac1.moby.moby294.update"
    | "rac1.moby.moby326.update"
    | "rac1.moby.edwina.update"
    | "rac1.moby.moby336.update"
    | "rac1.moby.moby339.update"
    | "rac1.moby.water_reservoir.update"
    | "rac1.moby.hoven_shot.update"
    | "rac1.moby.hoven_challenge.update"
    | "rac1.moby.moby1259.update"
    | "rac1.moby.moby1267.update"
    | "rac1.moby.hoven_homing_mine.update"
    | "rac1.moby.planetbuster_part.update"
    | "rac1.moby.door_switch.update"
    | "rac1.moby.moby1345.update"
    | "rac1.moby.blarg_commander.update"
    | "rac1.moby.cutscene_volume_trigger.update"
    | "rac1.moby.class_1557.update"
    | "rac1.moby.moby1901.update"
    | "rac1.moby.clip_volume_trigger.update"
    | "rac1.moby.elevator_21.update"
    | "rac1.moby.blarg_turret.update"
    | "rac1.moby.gem_lock_turret.update"
    | "rac1.moby.robosquawker.update"
    | "rac1.moby.fighter_jet_69.update"
    | "rac1.moby.homing_rocket82.update"
    | "rac1.moby.moby83.update"
    | "rac1.moby.blarg_space_fighter.update"
    | "rac1.moby.blarg_fighter111.update"
    | "rac1.moby.rotating_door.update"
    | "rac1.moby.forcefield_tower.update"
    | "rac1.moby.drifting_blob.update"
    | "rac1.moby.ship_pickup.update"
    | "rac1.moby.switch.update"
    | "rac1.moby.rocket295.update"
    | "rac1.moby.fade_in_hold_out.update"
    | "rac1.moby.qwark_starfighter_part.update"
    | "rac1.moby.starfighter_part.update"
    | "rac1.moby.gem_lock_pickup.update"
    | "rac1.moby.purple_ship_533.update"
    | "rac1.moby.help_volume.update"
    | "rac1.moby.moby_state_relay.update"
    | "rac1.moby.controlled_gate.update"
    | "rac1.moby.projectile_l13.update"
    | "rac1.moby.moby1261.update"
    | "rac1.moby.blarg_space_commando.update"
    | "rac1.moby.bobbing_lights.update"
    | "rac1.moby.lift1270.update"
    | "rac1.moby.class_1271.update"
    | "rac1.moby.moby1353.update"
    | "rac1.moby.class_1403.update"
    | "rac1.moby.sparks_trigger_l13.update"
    | "rac1.moby.watch_mobys.update"
    | "rac1.moby.moby1632.update"
    | "rac1.moby.moby1634.update"
    | "rac1.moby.moby1805.update"
    | "rac1.moby.keyframe_platform.update"
    | "rac1.moby.moby8.update"
    | "rac1.moby.plasmabot.update"
    | "rac1.moby.machinegun_turret_30.update"
    | "rac1.moby.minibomber.update"
    | "rac1.moby.moby81.update"
    | "rac1.moby.moby211.update"
    | "rac1.moby.moby250.update"
    | "rac1.moby.moby309.update"
    | "rac1.moby.debris_particle.update"
    | "rac1.moby.gem_lock_sentry.update"
    | "rac1.moby.race_debris.update"
    | "rac1.moby.path_lift.update"
    | "rac1.moby.moby610.update"
    | "rac1.moby.mine_l14.update"
    | "rac1.moby.sweeping_bolt.update"
    | "rac1.moby.class_684.update"
    | "rac1.moby.moby685.update"
    | "rac1.moby.taxi.update"
    | "rac1.moby.moby851.update"
    | "rac1.moby.moby908.update"
    | "rac1.moby.oltanis_jet.update"
    | "rac1.moby.flyer.update"
    | "rac1.moby.bolt_thief.update"
    | "rac1.moby.moby924.update"
    | "rac1.moby.floating_mine.update"
    | "rac1.moby.bouncing_spark.update"
    | "rac1.moby.moby1224.update"
    | "rac1.moby.moby1331.update"
    | "rac1.moby.triggered_unlock.update"
    | "rac1.moby.collectible_pickup.update"
    | "rac1.moby.moby1395.update"
    | "rac1.moby.moby1397.update"
    | "rac1.moby.step_on_switch.update"
    | "rac1.moby.blarg_interceptor.update"
    | "rac1.moby.queue_effect_draw.update"
    | "rac1.moby.skill_point.update"
    | "rac1.moby.sentrybot.update"
    | "rac1.moby.projectile.update"
    | "rac1.moby.moby67.update"
    | "rac1.moby.class_256.update"
    | "rac1.moby.scale_fade_and_delete.update"
    | "rac1.moby.moby1523.update"
    | "rac1.moby.moby77.update"
    | "rac1.moby.moby78.update"
    | "rac1.moby.sliding_gate.update"
    | "rac1.moby.clip_volume_door.update"
    | "rac1.moby.spiderbot.update"
    | "rac1.moby.class_148.update"
    | "rac1.moby.hit_reaction_effect_alt.update"
    | "rac1.moby.moving_moby.update"
    | "rac1.moby.construction_arm.update"
    | "rac1.moby.helicopter.update"
    | "rac1.moby.sentrybot_alarm.update"
    | "rac1.moby.ultramech.update"
    | "rac1.moby.class_655.update"
    | "rac1.moby.moby934.update"
    | "rac1.moby.class_937.update"
    | "rac1.moby.underwater_ring.update"
    | "rac1.moby.side_drift.update"
    | "rac1.moby.poison_vessel.update"
    | "rac1.moby.moby1388.update"
    | "rac1.moby.moby1257_spawner.update"
    | "rac1.moby.ripple_strips_moby.update"
    | "rac1.moby.moby1419.update"
    | "rac1.moby.class_1425.update"
    | "rac1.moby.moby1428.update"
    | "rac1.moby.codebot_slot.update"
    | "rac1.moby.ultramech_scientist.update"
    | "rac1.moby.giant_clank_pad.update"
    | "rac1.moby.moby1469.update"
    | "rac1.moby.boss_slot_effect.update"
    | "rac1.moby.homing_projectile.update"
    | "rac1.moby.homing_spark_1475.update"
    | "rac1.moby.moby257.update"
    | "rac1.moby.thrown_bomb.update"
    | "rac1.moby.moby470.update"
    | "rac1.moby.moby471.update"
    | "rac1.moby.test_dummy.update"
    | "rac1.moby.moby546.update"
    | "rac1.moby.moby552.update"
    | "rac1.moby.hoverboard_racer.update"
    | "rac1.moby.floating_enemy.update"
    | "rac1.moby.moby647.update"
    | "rac1.moby.moby650.update"
    | "rac1.moby.moby654.update"
    | "rac1.moby.moby800.update"
    | "rac1.moby.armed_transport.update"
    | "rac1.moby.watcher.update"
    | "rac1.moby.moby1387.update"
    | "rac1.moby.crate_platform.update"
    | "rac1.moby.path_pickup.update"
    | "rac1.moby.moby1439.update"
    | "rac1.moby.moby1441.update"
    | "rac1.moby.moby1442.update"
    | "rac1.moby.ring_effect.update"
    | "rac1.moby.wandering_helper.update"
    | "rac1.moby.challenge_npc.update"
    | "rac1.moby.banner_trigger.update"
    | "rac1.moby.path_walker.update"
    | "rac1.moby.spark_ring_emitter.update"
    | "rac1.moby.elevator_platform.update"
    | "rac1.moby.spinning_object.update"
    | "rac1.moby.target_activator.update"
    | "rac1.moby.env_map_a.update"
    | "rac1.moby.class_1947.update"
    | "rac1.moby.env_map_b.update"
    | "rac1.moby.class_1907.update"
    | "rac1.moby.env_map_c.update"
    | "rac1.moby.moby99.update"
    | "rac1.moby.fleet_turret.update"
    | "rac1.moby.moby669.update"
    | "rac1.moby.moby835.update"
    | "rac1.moby.stops_platform.update"
    | "rac1.moby.moby1368.update"
    | "rac1.moby.fighter_jet_1379.update"
    | "rac1.moby.moby1380.update"
    | "rac1.moby.moby1382.update"
    | "rac1.moby.moby1448.update"
    | "rac1.moby.moby1470.update"
    | "rac1.moby.moby750_spark_trigger.update"
    | "rac1.moby.fleet_reflection.update"
    | "rac1.moby.moby1843.update"
    | "rac1.moby.moby1873.update"
    | "rac1.moby.moby1876.update"
    | "rac1.moby.moby41.update"
    | "rac1.moby.moby564.update"
    | "rac1.moby.moby568.update"
    | "rac1.moby.path_junction.update"
    | "rac1.moby.energy_field_emitter.update"
    | "rac1.moby.timed_lift.update"
    | "rac1.moby.sinking_platform.update"
    | "rac1.moby.falling_fireball.update"
    | "rac1.moby.moby628.update"
    | "rac1.moby.vendor_moby.update"
    | "rac1.moby.hit_trigger.update"
    | "rac1.moby.homing_spark_983.update"
    | "rac1.moby.moby1355.update"
    | "rac1.moby.moby1381.update"
    | "rac1.moby.moby1392.update"
    | "rac1.moby.moby1402.update"
    | "rac1.moby.final_boss.update"
    | "rac1.moby.class_1432.update"
    | "rac1.moby.moby1434.update"
    | "rac1.moby.moby1454.update"
    | "rac1.moby.moby1563.update"
    | "rac1.moby.moby1568.update"
    | "rac1.moby.moby1584.update"
    | "rac1.moby.moby1799.update"
    | "rac1.moby.moby1906.update"
    | "Ammo_Add"
    | "Ammo_ChooseDrop"
    | "Ammo_Collect"
    | "Ammo_Pickup"
    | "Ammo_SpawnDrop"
    | "Damage_BuildHit"
    | "Damage_HitVictim"
    | "Damage_Resolve"
    | "FollowCamera_ApplyOverrides"
    | "GoldBolts_CountCollected"
    | "GoldBolts_CountUnspent"
    | "Help_Request"
    | "HeroItems_Attach"
    | "Hero_AdvanceAnimation"
    | "Hero_ApproachSpeed"
    | "Hero_ItemRequestApply"
    | "Hero_SetPlanarVelocity"
    | "Hero_TakeDamage"
    | "Hero_TurnToHeading"
    | "Hero_Update"
    | "Hero_UpdateMotionInput"
    | "Hud_HealthDraw"
    | "Hud_QuickSelect_Draw"
    | "Hud_QuickSelect_Init"
    | "Hud_QuickSelect_Update"
    | "Item_Give"
    | "Level_LoadGameplay"
    | "Menu_EquippedPreview_Draw"
    | "Menu_EquippedPreview_Update"
    | "Menu_ItemAmmo_Draw"
    | "Menu_ItemGrid_Draw"
    | "Menu_ItemGrid_Update"
    | "Menu_ItemSlots_Update"
    | "Menu_ItemText_Draw"
    | "Menu_Preview_Bind"
    | "Menu_Preview_DrawAvailable"
    | "Menu_Preview_DrawSelected"
    | "Menu_Preview_Update"
    | "Menu_QuickSelect_Draw"
    | "Menu_QuickSelect_Load"
    | "Menu_QuickSelect_Store"
    | "Moby_AgnoggShipFront_Update"
    | "Moby_AirshipPart1181_Update"
    | "Moby_AirshipPart_Update"
    | "Moby_AlienQueen_Update"
    | "Moby_AlienSnapper_Update"
    | "Moby_Ammocrate224_Update"
    | "Moby_Ammocrate_Update"
    | "Moby_Amoeboid_Update"
    | "Moby_ArmedTransport_Update"
    | "Moby_Asteroid212_Update"
    | "Moby_Asteroid_Update"
    | "Moby_BackgroundShip1_Update"
    | "Moby_BackgroundShip2_Update"
    | "Moby_Barrier_Update"
    | "Moby_BataliaDeserter_Update"
    | "Moby_Beehive_Update"
    | "Moby_BigAl_Update"
    | "Moby_BigAxebot_Update"
    | "Moby_Birdbot_Update"
    | "Moby_BlargBombthrower_Update"
    | "Moby_BlargCommander_Update"
    | "Moby_BlargEliteCommando_Update"
    | "Moby_BlargGun_Update"
    | "Moby_BlargGunner_Update"
    | "Moby_BlargHeavyInterceptor1417_Update"
    | "Moby_BlargHeavyInterceptor_Update"
    | "Moby_BlargHelicopter326_Update"
    | "Moby_BlargHelicopter_Update"
    | "Moby_BlargParatrooper_Update"
    | "Moby_BlargShip1319_Update"
    | "Moby_BlargShip1805_Update"
    | "Moby_BlargShip1843_Update"
    | "Moby_BlargShip_Update"
    | "Moby_BlargSpaceCommando1262_Update"
    | "Moby_BlargSpaceCommando_Update"
    | "Moby_BlargSpaceFighter111_Update"
    | "Moby_BlargSpaceFighter_Update"
    | "Moby_BlargTrooper294_Update"
    | "Moby_BlargTrooper_Update"
    | "Moby_BlargTurret_Update"
    | "Moby_BlockCave_Update"
    | "Moby_Bob_Update"
    | "Moby_BoltCrank_Update"
    | "Moby_BoltCrate_Update"
    | "Moby_BoltGrabber_Update"
    | "Moby_BoltThief1401_Update"
    | "Moby_BoltThief923_Update"
    | "Moby_BoltThief_Update"
    | "Moby_Bolt_Update"
    | "Moby_BoltcratePossiblyForMetalDetector_Update"
    | "Moby_Bomb248_Update"
    | "Moby_Bomb281_Update"
    | "Moby_Bomb425_Update"
    | "Moby_Bomb545_Update"
    | "Moby_Bomb882_Update"
    | "Moby_Bomb938_Update"
    | "Moby_BomberJet_Update"
    | "Moby_BomberTank_Update"
    | "Moby_Bombomatic_Update"
    | "Moby_BombthrowerGrass939_Update"
    | "Moby_BombthrowerGrass_Update"
    | "Moby_BotDoorLock_Update"
    | "Moby_Box_Update"
    | "Moby_BridgeHalf_Update"
    | "Moby_BridgePiece1_Update"
    | "Moby_Bridge_Update"
    | "Moby_Bulldozer_Update"
    | "Moby_Button1416_Update"
    | "Moby_Button_Update"
    | "Moby_CameraObject_Update"
    | "Moby_CaveDoor_Update"
    | "Moby_Chomper_Update"
    | "Moby_CircularSawEnemy_Update"
    | "Moby_ClankCutsceneTrigger_Update"
    | "Moby_Class1000_Update"
    | "Moby_Class1009_Update"
    | "Moby_Class1013_Update"
    | "Moby_Class1017_Update"
    | "Moby_Class1021_Update"
    | "Moby_Class1028_Update"
    | "Moby_Class1035_Update"
    | "Moby_Class1039_Update"
    | "Moby_Class1046_Update"
    | "Moby_Class1047_Update"
    | "Moby_Class1049_Update"
    | "Moby_Class1054_Update"
    | "Moby_Class1061_Update"
    | "Moby_Class1062_Update"
    | "Moby_Class1066_Update"
    | "Moby_Class1067_Update"
    | "Moby_Class1069_Update"
    | "Moby_Class1080_Update"
    | "Moby_Class1083_Update"
    | "Moby_Class1085_Update"
    | "Moby_Class1090_Update"
    | "Moby_Class1091_Update"
    | "Moby_Class1108_Update"
    | "Moby_Class1113_Update"
    | "Moby_Class1123_Update"
    | "Moby_Class1128_Update"
    | "Moby_Class112_Update"
    | "Moby_Class1133_Update"
    | "Moby_Class1138_Update"
    | "Moby_Class1142_Update"
    | "Moby_Class1156_Update"
    | "Moby_Class1157_Update"
    | "Moby_Class1158_Update"
    | "Moby_Class1159_Update"
    | "Moby_Class1180_Update"
    | "Moby_Class1193_Update"
    | "Moby_Class1199_Update"
    | "Moby_Class1206_Update"
    | "Moby_Class1219_Update"
    | "Moby_Class1221_Update"
    | "Moby_Class1224_Update"
    | "Moby_Class1225_Update"
    | "Moby_Class122_Update"
    | "Moby_Class1238_Update"
    | "Moby_Class1240_Update"
    | "Moby_Class1248_Update"
    | "Moby_Class1258_Update"
    | "Moby_Class1259_Update"
    | "Moby_Class1263_Update"
    | "Moby_Class1265_Update"
    | "Moby_Class1270_Update"
    | "Moby_Class1271_Update"
    | "Moby_Class127_Update"
    | "Moby_Class1292_Update"
    | "Moby_Class1293_Update"
    | "Moby_Class1324_Update"
    | "Moby_Class1331_Update"
    | "Moby_Class1341_Update"
    | "Moby_Class1342_Update"
    | "Moby_Class1343_Update"
    | "Moby_Class1344_Update"
    | "Moby_Class1345_Update"
    | "Moby_Class1347_Update"
    | "Moby_Class1348_Update"
    | "Moby_Class1349_Update"
    | "Moby_Class1350_Update"
    | "Moby_Class1352_Update"
    | "Moby_Class1353_Update"
    | "Moby_Class1368_Update"
    | "Moby_Class1378_Update"
    | "Moby_Class1381_Update"
    | "Moby_Class1387_Update"
    | "Moby_Class1392_Update"
    | "Moby_Class1394_Update"
    | "Moby_Class1395_Update"
    | "Moby_Class1397_Update"
    | "Moby_Class1400_Update"
    | "Moby_Class1402_Update"
    | "Moby_Class1403_Update"
    | "Moby_Class1404_Update"
    | "Moby_Class1405_Update"
    | "Moby_Class1413_Update"
    | "Moby_Class1418_Update"
    | "Moby_Class1419_Update"
    | "Moby_Class1425_Update"
    | "Moby_Class1427_Update"
    | "Moby_Class1432_Update"
    | "Moby_Class1469_Update"
    | "Moby_Class1470_Update"
    | "Moby_Class1471_Update"
    | "Moby_Class1479_Update"
    | "Moby_Class148_Update"
    | "Moby_Class1504_Update"
    | "Moby_Class1510_Update"
    | "Moby_Class1512_Update"
    | "Moby_Class1516_Update"
    | "Moby_Class1523_Update"
    | "Moby_Class1524_Update"
    | "Moby_Class152_Update"
    | "Moby_Class1544_Update"
    | "Moby_Class1545_Update"
    | "Moby_Class1546_Update"
    | "Moby_Class1548_Update"
    | "Moby_Class1549_Update"
    | "Moby_Class154_Update"
    | "Moby_Class1550_Update"
    | "Moby_Class1551_Update"
    | "Moby_Class1552_Update"
    | "Moby_Class1553_Update"
    | "Moby_Class1555_Update"
    | "Moby_Class1557_Update"
    | "Moby_Class1558_Update"
    | "Moby_Class1559_Update"
    | "Moby_Class1560_Update"
    | "Moby_Class1561_Update"
    | "Moby_Class1562_Update"
    | "Moby_Class1563_Update"
    | "Moby_Class156_Update"
    | "Moby_Class1577_Update"
    | "Moby_Class1584_Update"
    | "Moby_Class161_Update"
    | "Moby_Class1629_Update"
    | "Moby_Class1632_Update"
    | "Moby_Class1633_Update"
    | "Moby_Class1634_Update"
    | "Moby_Class1641_Update"
    | "Moby_Class1649_Update"
    | "Moby_Class1660_Update"
    | "Moby_Class1667_Update"
    | "Moby_Class166_Update"
    | "Moby_Class167_Update"
    | "Moby_Class1750_Update"
    | "Moby_Class1772_Update"
    | "Moby_Class1789_Update"
    | "Moby_Class1799_Update"
    | "Moby_Class179_Update"
    | "Moby_Class1812_Update"
    | "Moby_Class1848_Update"
    | "Moby_Class184_Update"
    | "Moby_Class1855_Update"
    | "Moby_Class1856_Update"
    | "Moby_Class1873_Update"
    | "Moby_Class1876_Update"
    | "Moby_Class1898_Update"
    | "Moby_Class1901_Update"
    | "Moby_Class1903_Update"
    | "Moby_Class1907_Update"
    | "Moby_Class1919_Update"
    | "Moby_Class1923_Update"
    | "Moby_Class193_Update"
    | "Moby_Class1943_Update"
    | "Moby_Class1947_Update"
    | "Moby_Class1948_Update"
    | "Moby_Class1953_Update"
    | "Moby_Class19_Update"
    | "Moby_Class22_Update"
    | "Moby_Class231_Update"
    | "Moby_Class235_Update"
    | "Moby_Class238_Update"
    | "Moby_Class23_Update"
    | "Moby_Class256_Update"
    | "Moby_Class257_Update"
    | "Moby_Class258_Update"
    | "Moby_Class279_Update"
    | "Moby_Class27_Update"
    | "Moby_Class293_Update"
    | "Moby_Class313_Update"
    | "Moby_Class317_Update"
    | "Moby_Class320_Update"
    | "Moby_Class325_Update"
    | "Moby_Class327_Update"
    | "Moby_Class352_Update"
    | "Moby_Class361_Update"
    | "Moby_Class367_Update"
    | "Moby_Class37_Update"
    | "Moby_Class386_Update"
    | "Moby_Class403_Update"
    | "Moby_Class417_Update"
    | "Moby_Class422_Update"
    | "Moby_Class428_Update"
    | "Moby_Class436_Update"
    | "Moby_Class438_Update"
    | "Moby_Class440_Update"
    | "Moby_Class441_Update"
    | "Moby_Class444_Update"
    | "Moby_Class463_Update"
    | "Moby_Class467_Update"
    | "Moby_Class468_Update"
    | "Moby_Class482_Update"
    | "Moby_Class552_Update"
    | "Moby_Class558_Update"
    | "Moby_Class567_Update"
    | "Moby_Class574_Update"
    | "Moby_Class582_Update"
    | "Moby_Class584_Update"
    | "Moby_Class600_Update"
    | "Moby_Class605_Update"
    | "Moby_Class610_Update"
    | "Moby_Class617_Update"
    | "Moby_Class621_Update"
    | "Moby_Class624_Update"
    | "Moby_Class628_Update"
    | "Moby_Class639_Update"
    | "Moby_Class644_Update"
    | "Moby_Class648_Update"
    | "Moby_Class654_Update"
    | "Moby_Class655_Update"
    | "Moby_Class65_Update"
    | "Moby_Class667_Update"
    | "Moby_Class669_Update"
    | "Moby_Class671_Update"
    | "Moby_Class674_Update"
    | "Moby_Class676_Update"
    | "Moby_Class678_Update"
    | "Moby_Class679_Update"
    | "Moby_Class67_Update"
    | "Moby_Class681_Update"
    | "Moby_Class684_Update"
    | "Moby_Class686_Update"
    | "Moby_Class6_Update"
    | "Moby_Class700_Update"
    | "Moby_Class702_Update"
    | "Moby_Class722_Update"
    | "Moby_Class737_Update"
    | "Moby_Class751_Update"
    | "Moby_Class761_Update"
    | "Moby_Class775_Update"
    | "Moby_Class779_Update"
    | "Moby_Class787_Update"
    | "Moby_Class78_Update"
    | "Moby_Class794_Update"
    | "Moby_Class800_Update"
    | "Moby_Class804_Update"
    | "Moby_Class809_Update"
    | "Moby_Class81_Update"
    | "Moby_Class832_Update"
    | "Moby_Class833_Update"
    | "Moby_Class835_Update"
    | "Moby_Class841_Update"
    | "Moby_Class843_Update"
    | "Moby_Class845_Update"
    | "Moby_Class848_Update"
    | "Moby_Class852_Update"
    | "Moby_Class855_Update"
    | "Moby_Class859_Update"
    | "Moby_Class86_Update"
    | "Moby_Class880_Update"
    | "Moby_Class885_Update"
    | "Moby_Class893_Update"
    | "Moby_Class895_Update"
    | "Moby_Class898_Update"
    | "Moby_Class899_Update"
    | "Moby_Class934_Update"
    | "Moby_Class937_Update"
    | "Moby_Class947_Update"
    | "Moby_Class982_Update"
    | "Moby_Class983_Update"
    | "Moby_Class994_Update"
    | "Moby_Class99_Update"
    | "Moby_CodebotSlot_Update"
    | "Moby_Codebot_Update"
    | "Moby_CollectBolt"
    | "Moby_Commando_Update"
    | "Moby_ConstructionArm_Update"
    | "Moby_Constructorbot1208_Update"
    | "Moby_Constructorbot_Update"
    | "Moby_ConveyorBelt1250_Update"
    | "Moby_ConveyorBelt471_Update"
    | "Moby_ConveyorBelt_Update"
    | "Moby_CraneArm_Update"
    | "Moby_Crane_Update"
    | "Moby_Decoy_Update"
    | "Moby_DeplanetizerGun1568_Update"
    | "Moby_DeplanetizerGun_Update"
    | "Moby_DestroyableCaveWall_Update"
    | "Moby_Display_Update"
    | "Moby_Door1359_Update"
    | "Moby_Door196_Update"
    | "Moby_Door647_Update"
    | "Moby_DoorHalf_Update"
    | "Moby_DoorLeft_Update"
    | "Moby_Door_Update"
    | "Moby_DrainCover_Update"
    | "Moby_DrekFightMissile_Update"
    | "Moby_DrekFinalBossRobot_Update"
    | "Moby_DreksFleetTurret_Update"
    | "Moby_Drone_Update"
    | "Moby_Edwina_Update"
    | "Moby_ElectricGate_Update"
    | "Moby_Elevator1150_Update"
    | "Moby_Elevator1826_Update"
    | "Moby_Elevator21_Update"
    | "Moby_Elevator685_Update"
    | "Moby_ElevatorWithButton_Update"
    | "Moby_Elevator_Update"
    | "Moby_EnergySphere1297_Update"
    | "Moby_EnergySphereHolder_Update"
    | "Moby_EnergySphere_Update"
    | "Moby_EudoraBridge_Update"
    | "Moby_Extermibot_Update"
    | "Moby_Extermitank_Update"
    | "Moby_FallingRock_Update"
    | "Moby_Fan_Update"
    | "Moby_FighterJet1379_Update"
    | "Moby_FighterJet69_Update"
    | "Moby_FighterJet_Update"
    | "Moby_FloatingPlatform587_Update"
    | "Moby_FloatingPlatform810_Update"
    | "Moby_FloatingPlatform_Update"
    | "Moby_FloorButton_Update"
    | "Moby_ForcefieldTower_Update"
    | "Moby_Forcefield_Update"
    | "Moby_Fred1_Update"
    | "Moby_FredPokitaru_Update"
    | "Moby_Fred_Update"
    | "Moby_Frog_Update"
    | "Moby_Gadgebot1906_Update"
    | "Moby_GadgebotSpawnContainer_Update"
    | "Moby_GadgebotSpawnPad_Update"
    | "Moby_GadgebotTelepotPad_Update"
    | "Moby_Gadgebot_Update"
    | "Moby_GadgetronCeo_Update"
    | "Moby_GadgetronSign_Update"
    | "Moby_Gate1_Update"
    | "Moby_Gate2_Update"
    | "Moby_Gate92_Update"
    | "Moby_Gate93_Update"
    | "Moby_Gate_Update"
    | "Moby_GetHitMessage"
    | "Moby_GiantClankPad_Update"
    | "Moby_GoldBolt_Update"
    | "Moby_GoldWeaponCase_Update"
    | "Moby_GrabCrane_Update"
    | "Moby_GreenMushroom_Update"
    | "Moby_GrindrailBarrier_Update"
    | "Moby_GrindrailButton_Update"
    | "Moby_GrindrailGate1441_Update"
    | "Moby_GrindrailGate_Update"
    | "Moby_Gun_Update"
    | "Moby_HangarDoor_Update"
    | "Moby_Helga_Update"
    | "Moby_Helicopter233_Update"
    | "Moby_Helicopter_Update"
    | "Moby_Helipack_Update"
    | "Moby_HelpDeskLady_Update"
    | "Moby_HomingMineSpawner_Update"
    | "Moby_HornyToad_Update"
    | "Moby_HovenTurret_Update"
    | "Moby_Hoverboard439_Update"
    | "Moby_HoverboardGirl_Update"
    | "Moby_HoverboardRing_Update"
    | "Moby_Hoverboard_Update"
    | "Moby_HydrodisplacerFaucet_Update"
    | "Moby_Hydrodisplacer_Update"
    | "Moby_Infobot_Update"
    | "Moby_Jet921_Update"
    | "Moby_JetFighter_Update"
    | "Moby_Jet_Update"
    | "Moby_LabDoor_Update"
    | "Moby_Lamp1511_Update"
    | "Moby_Lamp_Update"
    | "Moby_LargeAmoeboid_Update"
    | "Moby_Leaf_Update"
    | "Moby_Lieutenant_Update"
    | "Moby_LiftcarPlatform_Update"
    | "Moby_MachinegunTurret30_Update"
    | "Moby_MachinegunTurret_Update"
    | "Moby_MagnetElevator_Update"
    | "Moby_Magnetboots_Update"
    | "Moby_MetalDetector_Update"
    | "Moby_MetropolisTrainCarriage_Update"
    | "Moby_MetropolisTrainLocomotive_Update"
    | "Moby_Mine1112_Update"
    | "Moby_Mine1269_Update"
    | "Moby_Mine568_Update"
    | "Moby_Mine627_Update"
    | "Moby_Mine643_Update"
    | "Moby_Mine77_Update"
    | "Moby_Mine83_Update"
    | "Moby_Mine933_Update"
    | "Moby_MineLayer_Update"
    | "Moby_Miner_Update"
    | "Moby_Minibomber_Update"
    | "Moby_Morphoray1354_Update"
    | "Moby_MorphorayChicken_Update"
    | "Moby_MovingPlatformSmall_Update"
    | "Moby_MushroomUnderside_Update"
    | "Moby_Mushroom_Update"
    | "Moby_NanotechBall_Update"
    | "Moby_NanotechCrateFragment_Update"
    | "Moby_NanotechUpgradeVendor_Update"
    | "Moby_NovalisElevator_Update"
    | "Moby_OceanAridia_Update"
    | "Moby_OceanPokitaru_Update"
    | "Moby_OceanRilgar_Update"
    | "Moby_OceanUmbris_Update"
    | "Moby_OilTankerFront_Update"
    | "Moby_ParticleSpawnerSmokeFire_Update"
    | "Moby_Peckbot_Update"
    | "Moby_PilotsHelmet_Update"
    | "Moby_PipeMountedGrating_Update"
    | "Moby_Pipe_Update"
    | "Moby_PistonPlatform_Update"
    | "Moby_PlanetbusterMaximusPart_Update"
    | "Moby_Plasmabot211_Update"
    | "Moby_PlasmabotHatch_Update"
    | "Moby_Plasmabot_Update"
    | "Moby_Platform1033_Update"
    | "Moby_Platform1117_Update"
    | "Moby_Platform240_Update"
    | "Moby_Platform309_Update"
    | "Moby_Platform664_Update"
    | "Moby_Platform903_Update"
    | "Moby_PlatformBooster_Update"
    | "Moby_Platform_Update"
    | "Moby_PoisonVessel1257_Update"
    | "Moby_PoisonVessel_Update"
    | "Moby_PokitaruBoat_Update"
    | "Moby_Psytcopus_Update"
    | "Moby_Pterodactyl_Update"
    | "Moby_Puffoid_Update"
    | "Moby_PurpleShip533_Update"
    | "Moby_PurpleShip_Update"
    | "Moby_QwarkOltanis_Update"
    | "Moby_QwarkUmbris_Update"
    | "Moby_QwarksBouncer_Update"
    | "Moby_QwarksStarfighterPart389_Update"
    | "Moby_QwarksStarfighterPart_Update"
    | "Moby_QwarksTrailer_Update"
    | "Moby_RecordDeath"
    | "Moby_RedButton_Update"
    | "Moby_RedOrb_Update"
    | "Moby_RedShip1_Update"
    | "Moby_RefuelingStation_Update"
    | "Moby_ResortOwner_Update"
    | "Moby_RoboShackSign_Update"
    | "Moby_Robosquawker_Update"
    | "Moby_RobotDog1382_Update"
    | "Moby_RobotDog_Update"
    | "Moby_RobotQwark_Update"
    | "Moby_RockFormation_Update"
    | "Moby_Rock_Update"
    | "Moby_Rocket1034_Update"
    | "Moby_Rocket1475_Update"
    | "Moby_Rocket295_Update"
    | "Moby_Rocket409_Update"
    | "Moby_Rocket41_Update"
    | "Moby_Rocket435_Update"
    | "Moby_Rocket458_Update"
    | "Moby_Rocket470_Update"
    | "Moby_Rocket49_Update"
    | "Moby_Rocket50_Update"
    | "Moby_Rocket564_Update"
    | "Moby_Rocket819_Update"
    | "Moby_Rocket82_Update"
    | "Moby_Rocket922_Update"
    | "Moby_RocketDoor1_Update"
    | "Moby_RocketLauncher_Update"
    | "Moby_RocketTank_Update"
    | "Moby_Rocks_Update"
    | "Moby_Sam_Update"
    | "Moby_SandMouse_Update"
    | "Moby_SandSharkNest_Update"
    | "Moby_SandShark_Update"
    | "Moby_SandmouseHouse_Update"
    | "Moby_Sandmouse_Update"
    | "Moby_SandsharkEgg_Update"
    | "Moby_SceneryShip_Update"
    | "Moby_Scoutbot_Update"
    | "Moby_Screamer_Update"
    | "Moby_Seeker_Update"
    | "Moby_SeesawPlatform_Update"
    | "Moby_SentrybotAlarm_Update"
    | "Moby_Sentrybot_Update"
    | "Moby_ShadySalesman_Update"
    | "Moby_Sharkigator1059_Update"
    | "Moby_Sharkigator_Update"
    | "Moby_Shrub_Update"
    | "Moby_Shuttle1448_Update"
    | "Moby_Shuttle1766_Update"
    | "Moby_Shuttle424_Update"
    | "Moby_Shuttle557_Update"
    | "Moby_Shuttle_Update"
    | "Moby_SkidMcmarx717_Update"
    | "Moby_SkidMcmarx_Update"
    | "Moby_SkidsAgent_Update"
    | "Moby_Snagglebeast_Update"
    | "Moby_SnowPlow_Update"
    | "Moby_SpawnPoint_Update"
    | "Moby_Spawner1885_Update"
    | "Moby_SpawnerEgg_Update"
    | "Moby_Spawner_Update"
    | "Moby_Spiderbot_Update"
    | "Moby_StationaryShip_Update"
    | "Moby_Statue_Update"
    | "Moby_SuckCannon_Update"
    | "Moby_SwingshotHook_Update"
    | "Moby_SwingshotVersatarget_Update"
    | "Moby_TallShroom_Update"
    | "Moby_Taxi1012_Update"
    | "Moby_Taxi1410_Update"
    | "Moby_Taxi712_Update"
    | "Moby_Taxi998_Update"
    | "Moby_TaxiPlatform1474_Update"
    | "Moby_TaxiPlatform_Update"
    | "Moby_Taxi_Update"
    | "Moby_Teleporter318_Update"
    | "Moby_Teleporter_Update"
    | "Moby_Television_Update"
    | "Moby_TestDummyDoor_Update"
    | "Moby_TestDummyOnHoverboard_Update"
    | "Moby_TestDummy_Update"
    | "Moby_ThePlumberBatalia_Update"
    | "Moby_ThePlumber_Update"
    | "Moby_ThrusterPackLockGreen_Update"
    | "Moby_ThrusterPackLockRed_Update"
    | "Moby_ThrusterPackLock_Update"
    | "Moby_TimedActivationPads_Update"
    | "Moby_ToxicCrab_Update"
    | "Moby_ToxicGasVent_Update"
    | "Moby_TrackdriveLeft_Update"
    | "Moby_TransportPod_Update"
    | "Moby_TransportShip_Update"
    | "Moby_Trespasser_Update"
    | "Moby_TresspasserDoor1_Update"
    | "Moby_TresspasserDoor2_Update"
    | "Moby_TresspasserPad_Update"
    | "Moby_Tresspasser_Update"
    | "Moby_Turret_Update"
    | "Moby_UltramechScientist_Update"
    | "Moby_UltramechUnlimited_Update"
    | "Moby_UnderwaterRing_Update"
    | "Moby_UpperDoor_Update"
    | "Moby_VeldinRobotEnemy_Update"
    | "Moby_VeldinShip_Update"
    | "Moby_VendorOrb_Update"
    | "Moby_Vendor_Update"
    | "Moby_WallButton_Update"
    | "Moby_Water902_Update"
    | "Moby_WaterCurrent_Update"
    | "Moby_WaterLily_Update"
    | "Moby_WaterReservoir_Update"
    | "Moby_Water_Update"
    | "Moby_WhiteFlower_Update"
    | "Moby_WoodcutBot_Update"
    | "Pad_ProcessReport"
    | "Planet_Unlock"
    | "Pyrocitor_FlameCreate"
    | "Save_NewGame"
    | "Save_NewGamePlus"
    | "Save_Prepare"
    | "Save_RequestAutosave"
    | "Save_Restore"
    | "Save_RestoreData"
    | "Save_Serialize"
    | "Save_UpdateState"
    | "Ship_InitTransition"
    | "Ship_TravelTo"
    | "Vendor_BuildItemList"
    | "Vendor_InitLevelStock"
    | "Vendor_InitializeSelected"
    | "Vendor_MenuUpdate"
    | "Vendor_OpenMenu"
    | "Weapon_Blaster_Fire"
    | "Weapon_Blaster_PickTarget"
    | "Weapon_Blaster_Update"
    | "Weapon_BombGlove_Fire"
    | "Weapon_BombGlove_Update"
    | "Weapon_Decoy_Update"
    | "Weapon_Devastator_Fire"
    | "Weapon_Devastator_Update"
    | "Weapon_Drone_PickTarget"
    | "Weapon_GloveOfDoom_Fire"
    | "Weapon_GloveOfDoom_Update"
    | "Weapon_GoldDevastator_PickTarget"
    | "Weapon_MineGlove_Fire"
    | "Weapon_MineGlove_Update"
    | "Weapon_MorphORay_Update"
    | "Weapon_Pyrocitor_Update"
    | "Weapon_Ryno_Fire"
    | "Weapon_Ryno_PickTarget"
    | "Weapon_Ryno_Update"
    | "Weapon_SuckCannon_Update"
    | "Weapon_TakeAmmo"
    | "Weapon_Taunter_Update"
    | "Weapon_TeslaClaw_Update"
    | "Weapon_Visibomb_Fire"
    | "Weapon_Visibomb_Update"
    | "Weapon_Walloper_Update"
    | "Wrench_SwingSweep"
    | "Wrench_ThrowRelease"
    | "Wrench_Update"
    | "blast_apply"
    | "collide_segment"
    | "collide_sphere_mobys"
    | "moby_create"
    | "moby_delete"
    | "msg_string"
    | "projectile_blaster_shot_update"
    | "projectile_bomb_update"
    | "projectile_devastator_rocket_update"
    | "projectile_doom_agent_update"
    | "projectile_doom_capsule_update"
    | "projectile_mine_update"
    | "projectile_ryno_rocket_update"
    | "projectile_visibomb_update"
type MemoryType = "u8" | "i8" | "u16" | "i16" | "u32" | "i32" | "f32"

type Fields = {
    hero: {
        position: {
            x: number, -- Where the hero is (gHeroPos).
            y: number,
            z: number,
        },
        facing: number, -- The way he faces (rot.z), in radians.
        move_yaw: number, -- Where the stick moves him: the stick's angle plus the camera's yaw.
        state: number, -- read-only; His state: 0 standing, 2 running, 7 jumping, ...
    },
    bolts: number, -- The player's bolts.
    omni: {
        weapon: {
            wrench: {
                have: number, -- Omniwrench (item 8): 1 when the player owns it (the have byte table at 0x13d4c0).
            },
            suck_cannon: {
                have: number, -- Suck Cannon (item 9): 1 when the player owns it (the have byte table at 0x13d4c0).
                ammo: number, -- Suck Cannon (item 9): its ammo (the ammo int table at 0x13d428).
                gold: number, -- Suck Cannon (item 9): 1 when it is the gold version (byte table at 0x13e520, saved with the game).
                gold_price: number, -- Suck Cannon (item 9): the price of its gold version in bolts (u16 at +0x14 of its price row; retail 10000). The Gold Weapon Cases charge this and print it in their offer text. Overlay data: the address is in the host's overlay window (0x40000000 + the NTSC-U level-0 address, the host maps it to the level now loaded); the game reloads the table with every level, so a mod writes it again on `level_loaded`. A u16: at most 65535.
            },
            bomb_glove: {
                have: number, -- Bomb Glove (item 10): 1 when the player owns it (the have byte table at 0x13d4c0).
                ammo: number, -- Bomb Glove (item 10): its ammo (the ammo int table at 0x13d428).
                gold: number, -- Bomb Glove (item 10): 1 when it is the gold version (byte table at 0x13e520, saved with the game).
                max_ammo: number, -- Bomb Glove (item 10): the most ammo it can hold (u16 at +0xe of its price row; AddAmmo caps at it; retail 40). Overlay data: the address is in the host's overlay window (0x40000000 + the NTSC-U level-0 address, the host maps it to the level now loaded), so a read or write works in a level and fails on the title screen / between levels; the game reloads the table with every level, so a mod writes it again on `level_loaded`.
                gold_price: number, -- Bomb Glove (item 10): the price of its gold version in bolts (u16 at +0x14 of its price row; retail 20000). The Gold Weapon Cases charge this and print it in their offer text. Overlay data: the address is in the host's overlay window (0x40000000 + the NTSC-U level-0 address, the host maps it to the level now loaded); the game reloads the table with every level, so a mod writes it again on `level_loaded`. A u16: at most 65535.
            },
            devastator: {
                have: number, -- Devastator (item 11): 1 when the player owns it (the have byte table at 0x13d4c0).
                ammo: number, -- Devastator (item 11): its ammo (the ammo int table at 0x13d428).
                gold: number, -- Devastator (item 11): 1 when it is the gold version (byte table at 0x13e520, saved with the game).
                max_ammo: number, -- Devastator (item 11): the most ammo it can hold (u16 at +0xe of its price row; AddAmmo caps at it; retail 20). Overlay data: the address is in the host's overlay window (0x40000000 + the NTSC-U level-0 address, the host maps it to the level now loaded), so a read or write works in a level and fails on the title screen / between levels; the game reloads the table with every level, so a mod writes it again on `level_loaded`.
                gold_price: number, -- Devastator (item 11): the price of its gold version in bolts (u16 at +0x14 of its price row; retail 60000). The Gold Weapon Cases charge this and print it in their offer text. Overlay data: the address is in the host's overlay window (0x40000000 + the NTSC-U level-0 address, the host maps it to the level now loaded); the game reloads the table with every level, so a mod writes it again on `level_loaded`. A u16: at most 65535.
            },
            visibomb: {
                have: number, -- Visibomb Gun (item 13): 1 when the player owns it (the have byte table at 0x13d4c0).
                ammo: number, -- Visibomb Gun (item 13): its ammo (the ammo int table at 0x13d428).
                gold: number, -- Visibomb Gun (item 13): 1 when it is the gold version (byte table at 0x13e520, saved with the game).
                max_ammo: number, -- Visibomb Gun (item 13): the most ammo it can hold (u16 at +0xe of its price row; AddAmmo caps at it; retail 20). Overlay data: the address is in the host's overlay window (0x40000000 + the NTSC-U level-0 address, the host maps it to the level now loaded), so a read or write works in a level and fails on the title screen / between levels; the game reloads the table with every level, so a mod writes it again on `level_loaded`.
            },
            taunter: {
                have: number, -- Taunter (item 14): 1 when the player owns it (the have byte table at 0x13d4c0).
                ammo: number, -- Taunter (item 14): its ammo (the ammo int table at 0x13d428).
                gold: number, -- Taunter (item 14): 1 when it is the gold version (byte table at 0x13e520, saved with the game).
            },
            blaster: {
                have: number, -- Blaster (item 15): 1 when the player owns it (the have byte table at 0x13d4c0).
                ammo: number, -- Blaster (item 15): its ammo (the ammo int table at 0x13d428).
                gold: number, -- Blaster (item 15): 1 when it is the gold version (byte table at 0x13e520, saved with the game).
                max_ammo: number, -- Blaster (item 15): the most ammo it can hold (u16 at +0xe of its price row; AddAmmo caps at it; retail 200). Overlay data: the address is in the host's overlay window (0x40000000 + the NTSC-U level-0 address, the host maps it to the level now loaded), so a read or write works in a level and fails on the title screen / between levels; the game reloads the table with every level, so a mod writes it again on `level_loaded`.
                gold_price: number, -- Blaster (item 15): the price of its gold version in bolts (u16 at +0x14 of its price row; retail 20000). The Gold Weapon Cases charge this and print it in their offer text. Overlay data: the address is in the host's overlay window (0x40000000 + the NTSC-U level-0 address, the host maps it to the level now loaded); the game reloads the table with every level, so a mod writes it again on `level_loaded`. A u16: at most 65535.
            },
            pyrocitor: {
                have: number, -- Pyrocitor (item 16): 1 when the player owns it (the have byte table at 0x13d4c0).
                ammo: number, -- Pyrocitor (item 16): its ammo (the ammo int table at 0x13d428).
                gold: number, -- Pyrocitor (item 16): 1 when it is the gold version (byte table at 0x13e520, saved with the game).
                max_ammo: number, -- Pyrocitor (item 16): the most ammo it can hold (u16 at +0xe of its price row; AddAmmo caps at it; retail 240). Overlay data: the address is in the host's overlay window (0x40000000 + the NTSC-U level-0 address, the host maps it to the level now loaded), so a read or write works in a level and fails on the title screen / between levels; the game reloads the table with every level, so a mod writes it again on `level_loaded`.
                gold_price: number, -- Pyrocitor (item 16): the price of its gold version in bolts (u16 at +0x14 of its price row; retail 30000). The Gold Weapon Cases charge this and print it in their offer text. Overlay data: the address is in the host's overlay window (0x40000000 + the NTSC-U level-0 address, the host maps it to the level now loaded); the game reloads the table with every level, so a mod writes it again on `level_loaded`. A u16: at most 65535.
            },
            mine_glove: {
                have: number, -- Mine Glove (item 17): 1 when the player owns it (the have byte table at 0x13d4c0).
                ammo: number, -- Mine Glove (item 17): its ammo (the ammo int table at 0x13d428).
                gold: number, -- Mine Glove (item 17): 1 when it is the gold version (byte table at 0x13e520, saved with the game).
                max_ammo: number, -- Mine Glove (item 17): the most ammo it can hold (u16 at +0xe of its price row; AddAmmo caps at it; retail 50). Overlay data: the address is in the host's overlay window (0x40000000 + the NTSC-U level-0 address, the host maps it to the level now loaded), so a read or write works in a level and fails on the title screen / between levels; the game reloads the table with every level, so a mod writes it again on `level_loaded`.
                gold_price: number, -- Mine Glove (item 17): the price of its gold version in bolts (u16 at +0x14 of its price row; retail 10000). The Gold Weapon Cases charge this and print it in their offer text. Overlay data: the address is in the host's overlay window (0x40000000 + the NTSC-U level-0 address, the host maps it to the level now loaded); the game reloads the table with every level, so a mod writes it again on `level_loaded`. A u16: at most 65535.
            },
            walloper: {
                have: number, -- Walloper (item 18): 1 when the player owns it (the have byte table at 0x13d4c0).
                ammo: number, -- Walloper (item 18): its ammo (the ammo int table at 0x13d428).
                gold: number, -- Walloper (item 18): 1 when it is the gold version (byte table at 0x13e520, saved with the game).
            },
            tesla_claw: {
                have: number, -- Tesla Claw (item 19): 1 when the player owns it (the have byte table at 0x13d4c0).
                ammo: number, -- Tesla Claw (item 19): its ammo (the ammo int table at 0x13d428).
                gold: number, -- Tesla Claw (item 19): 1 when it is the gold version (byte table at 0x13e520, saved with the game).
                max_ammo: number, -- Tesla Claw (item 19): the most ammo it can hold (u16 at +0xe of its price row; AddAmmo caps at it; retail 240). Overlay data: the address is in the host's overlay window (0x40000000 + the NTSC-U level-0 address, the host maps it to the level now loaded), so a read or write works in a level and fails on the title screen / between levels; the game reloads the table with every level, so a mod writes it again on `level_loaded`.
                gold_price: number, -- Tesla Claw (item 19): the price of its gold version in bolts (u16 at +0x14 of its price row; retail 60000). The Gold Weapon Cases charge this and print it in their offer text. Overlay data: the address is in the host's overlay window (0x40000000 + the NTSC-U level-0 address, the host maps it to the level now loaded); the game reloads the table with every level, so a mod writes it again on `level_loaded`. A u16: at most 65535.
            },
            glove_of_doom: {
                have: number, -- Glove of Doom (item 20): 1 when the player owns it (the have byte table at 0x13d4c0).
                ammo: number, -- Glove of Doom (item 20): its ammo (the ammo int table at 0x13d428).
                gold: number, -- Glove of Doom (item 20): 1 when it is the gold version (byte table at 0x13e520, saved with the game).
                max_ammo: number, -- Glove of Doom (item 20): the most ammo it can hold (u16 at +0xe of its price row; AddAmmo caps at it; retail 10). Overlay data: the address is in the host's overlay window (0x40000000 + the NTSC-U level-0 address, the host maps it to the level now loaded), so a read or write works in a level and fails on the title screen / between levels; the game reloads the table with every level, so a mod writes it again on `level_loaded`.
                gold_price: number, -- Glove of Doom (item 20): the price of its gold version in bolts (u16 at +0x14 of its price row; retail 10000). The Gold Weapon Cases charge this and print it in their offer text. Overlay data: the address is in the host's overlay window (0x40000000 + the NTSC-U level-0 address, the host maps it to the level now loaded); the game reloads the table with every level, so a mod writes it again on `level_loaded`. A u16: at most 65535.
            },
            morph_o_ray: {
                have: number, -- Morph-o-Ray (item 21): 1 when the player owns it (the have byte table at 0x13d4c0).
                ammo: number, -- Morph-o-Ray (item 21): its ammo (the ammo int table at 0x13d428).
                gold: number, -- Morph-o-Ray (item 21): 1 when it is the gold version (byte table at 0x13e520, saved with the game).
                gold_price: number, -- Morph-o-Ray (item 21): the price of its gold version in bolts (u16 at +0x14 of its price row; retail 20000). The Gold Weapon Cases charge this and print it in their offer text. Overlay data: the address is in the host's overlay window (0x40000000 + the NTSC-U level-0 address, the host maps it to the level now loaded); the game reloads the table with every level, so a mod writes it again on `level_loaded`. A u16: at most 65535.
            },
            ryno: {
                have: number, -- R.Y.N.O. (item 23): 1 when the player owns it (the have byte table at 0x13d4c0).
                ammo: number, -- R.Y.N.O. (item 23): its ammo (the ammo int table at 0x13d428).
                gold: number, -- R.Y.N.O. (item 23): 1 when it is the gold version (byte table at 0x13e520, saved with the game).
                max_ammo: number, -- R.Y.N.O. (item 23): the most ammo it can hold (u16 at +0xe of its price row; AddAmmo caps at it; retail 50). Overlay data: the address is in the host's overlay window (0x40000000 + the NTSC-U level-0 address, the host maps it to the level now loaded), so a read or write works in a level and fails on the title screen / between levels; the game reloads the table with every level, so a mod writes it again on `level_loaded`.
            },
            drone_device: {
                have: number, -- Drone Device (item 24): 1 when the player owns it (the have byte table at 0x13d4c0).
                ammo: number, -- Drone Device (item 24): its ammo (the ammo int table at 0x13d428).
                gold: number, -- Drone Device (item 24): 1 when it is the gold version (byte table at 0x13e520, saved with the game).
                max_ammo: number, -- Drone Device (item 24): the most ammo it can hold (u16 at +0xe of its price row; AddAmmo caps at it; retail 10). Overlay data: the address is in the host's overlay window (0x40000000 + the NTSC-U level-0 address, the host maps it to the level now loaded), so a read or write works in a level and fails on the title screen / between levels; the game reloads the table with every level, so a mod writes it again on `level_loaded`.
            },
            decoy: {
                have: number, -- Decoy Glove (item 25): 1 when the player owns it (the have byte table at 0x13d4c0).
                ammo: number, -- Decoy Glove (item 25): its ammo (the ammo int table at 0x13d428).
                gold: number, -- Decoy Glove (item 25): 1 when it is the gold version (byte table at 0x13e520, saved with the game).
                max_ammo: number, -- Decoy Glove (item 25): the most ammo it can hold (u16 at +0xe of its price row; AddAmmo caps at it; retail 20). Overlay data: the address is in the host's overlay window (0x40000000 + the NTSC-U level-0 address, the host maps it to the level now loaded), so a read or write works in a level and fails on the title screen / between levels; the game reloads the table with every level, so a mod writes it again on `level_loaded`.
                gold_price: number, -- Decoy Glove (item 25): the price of its gold version in bolts (u16 at +0x14 of its price row; retail 10000). The Gold Weapon Cases charge this and print it in their offer text. Overlay data: the address is in the host's overlay window (0x40000000 + the NTSC-U level-0 address, the host maps it to the level now loaded); the game reloads the table with every level, so a mod writes it again on `level_loaded`. A u16: at most 65535.
            },
            equipped: number, -- The item id in the hero's first item slot (the equipped weapon: 8 wrench, 10 Bomb Glove, ...; slot table 0x1403e0, stride 0x50, id at +0x28). The pal column of every omni.* field is ntsc + 0x100 [?: unverified, the script binding replaces it with the ntsc column on this disc].
            quick_select: number, -- Quick-select wheel entry 0: an item id (0 = empty). The wheel has 8 entries of 4 bytes: omni.weapon.quick_select.1 .. .7 are the others.
        },
        menu: {
            weapons_page: {
                highlight_class: number, -- Pause menu, Weapons page: the moby class of the 3D model of the highlighted item (overlay global 0x1b9e10 in Veldin, written by the page's item function 0x27b808 when the cursor lands on a weapon; 0xFFFFFFFF = nothing yet; e.g. Bomb Glove 192, item 16 -> 176, item 15 -> 168, item 11 -> 157, item 19 -> 177; it follows the cursor one tick later). Overlay data in the host's overlay window: reads fail outside a level. It is the model class, not the item id: the id is *(u16*)(*(S+0x48) + *(S+0x3c)*10 + 6) with S = *(*(0x1b9cf4)+0x40) (a pointer chain, no plain field).
            },
        },
        hud: {
            ammo_box: {
                max: number, -- The HUD ammo box: the maximum it shows right now, the N of the printed "count/N" (element +0x08). The game copies it from the weapon's cap only when the box is created, so after a cap change on the weapon that stays held (a level-up) the box keeps the old N until the weapon is switched or holstered; a mod writes the new cap here (and to def_max) and the box shows it on the next frame. Meaningful only while the box shows (the id field says which weapon it belongs to). Overlay data in the host's overlay window (0x40000000 + the NTSC-U level-0 address, the host maps it to the level now loaded), so a read or write works in a level and fails on the title screen / between levels. Slot 0 of the game's 4-slot HUD element array (stride 0x90; Veldin 0x17dc50) is the ammo box.
                def_max: number, -- The HUD ammo box: the maximum the game compares when it re-requests the box every tick (element +0x28). If it differs from the weapon's current cap the game restarts the box (fade out, fade in) to load the new one; write the same value as omni.hud.ammo_box.max so the compare finds an identical request and no restart happens. Overlay data in the host's overlay window (0x40000000 + the NTSC-U level-0 address, the host maps it to the level now loaded), so a read or write works in a level and fails on the title screen / between levels. Slot 0 of the game's 4-slot HUD element array (stride 0x90; Veldin 0x17dc50) is the ammo box.
                id: number, -- The HUD ammo box: the id of the element in slot 0 (element +0x20): 60000 + the item id of the weapon the box shows, 0xFFFF when the slot is empty. Read-only for mods; check it before writing max / def_max. Overlay data in the host's overlay window (0x40000000 + the NTSC-U level-0 address, the host maps it to the level now loaded), so a read or write works in a level and fails on the title screen / between levels. Slot 0 of the game's 4-slot HUD element array (stride 0x90; Veldin 0x17dc50) is the ammo box.
            },
        },
        challenge: number, -- The New Game+ (challenge mode) counter: 0 on the first playthrough, +1 each time New Game+ is started (kept in the save).
        hero: {
            held_moby: number, -- The moby of the weapon in Ratchet's hand: word 0 of hero item slot 0 (slot table 0x1403e0, stride 0x50). 0 when nothing is held. The Blaster is class 168 (item 15; the Bomb Glove is 192); read its class with struct("moby", addr).class. The pal column of every omni.* field is ntsc + 0x100 [?: unverified, the script binding replaces it with the ntsc column on this disc].
            moby: number, -- Ratchet's own moby (a pointer cell; the owner argument of the weapon creators; class 0). Read it as struct("moby", addr): position x/y/z, basis rows row0_x..row2_w. The pal column of every omni.* field is ntsc + 0x100 [?: unverified, the script binding replaces it with the ntsc column on this disc].
            health: number, -- Ratchet's health: the nanotech orbs the HUD shows (1 to omni.hero.max_health; 0 = dead). Hero_TakeDamage takes at most 1 a call; the game sets it to the maximum when a level starts and after a death, a nanotech pickup adds 1 (up to the maximum). A mod may write it (1 .. max while he is alive): the HUD meter shows the new value. Checked on both discs (PAL v1.00 and USA use the same address, 2026-10-25); the pal column is ntsc + 0x100 [?: unverified, the script binding reads the ntsc column on this disc].
            max_health: number, -- Ratchet's maximum health in nanotech orbs: 4, 5 with Premium Nanotech, 8 with Ultra Nanotech (the game sets it from the upgrades; its HUD draws at most 8). Checked on both discs (same address, initial value 4 in the boot data, 2026-10-25); the pal column is ntsc + 0x100 [?: unverified, the script binding reads the ntsc column on this disc].
            right_hand: {
                x: number, -- World x (metres) of the hero's right hand attach point (attach matrix 0, the weapon grip: the translation row at +0x30 of the 4x4 world matrix at 0x13fe10 that HeroComputeAttachMatrices fills each tick). A held weapon sits exactly here after HeroItemsAttach. The other attach matrices (9 of them, stride 0x40) are not fields: call moby_attach_to_joint (left hand = attach 14). The pal column of every omni.* field is ntsc + 0x100 [?: unverified, the script binding replaces it with the ntsc column on this disc].
                y: number, -- World y (metres) of the hero's right hand attach point (attach matrix 0, the weapon grip: the translation row at +0x30 of the 4x4 world matrix at 0x13fe10 that HeroComputeAttachMatrices fills each tick). A held weapon sits exactly here after HeroItemsAttach. The other attach matrices (9 of them, stride 0x40) are not fields: call moby_attach_to_joint (left hand = attach 14). The pal column of every omni.* field is ntsc + 0x100 [?: unverified, the script binding replaces it with the ntsc column on this disc].
                z: number, -- World z (metres) of the hero's right hand attach point (attach matrix 0, the weapon grip: the translation row at +0x30 of the 4x4 world matrix at 0x13fe10 that HeroComputeAttachMatrices fills each tick). A held weapon sits exactly here after HeroItemsAttach. The other attach matrices (9 of them, stride 0x40) are not fields: call moby_attach_to_joint (left hand = attach 14). The pal column of every omni.* field is ntsc + 0x100 [?: unverified, the script binding replaces it with the ntsc column on this disc].
            },
        },
    },
}

-- rac1.moby.item_offer.update (Moby_GoldWeaponCase_Update) void(u32): Per-tick update of a Gold Weapon Case (moby class 304) and of its display moby (classes 1456..1465), the retail seller of gold weapons (Novalis and Gerhardt's gold weapons): it tests the bolts, the item and the player's pad and sells. The omni extension's rac1.omni.goldcase.update. Levels of the Oozla family only.
type Moby_GoldWeaponCase_UpdateFn = (moby: number) -> ()
-- rac1.omni.weapon.ryno.fire (Weapon_Ryno_Fire) u32(u32,u32,u32,f32,f32,f32): Creates an R.Y.N.O. rocket (class 457): height = a height offset added to the target aim point, yaw and pitch of the rocket, owner = the moby that fires, pos = its start, target = the aimed target. Returns the rocket moby. Every level. (The script is given the floats first, as the omni extension lists them.)
type Weapon_Ryno_FireFn = (owner: number, pos: number, target: number, height: number, yaw: number, pitch: number) -> number
-- rac1.omni.moby.delete (moby_delete) void(u32): The game's moby deletion (DeleteMoby, in the executable: every level's copy of the address runs it): removes a moby (a projectile's death, a killed enemy). The only code that writes the deleted state. Every level.
type moby_deleteFn = (moby: number) -> ()
-- rac1.pad.process_report (Pad_ProcessReport) void(u32,u32,i32): One pad report into the pad's state (PadState, at pad), each poll, before the tick reads it.
type Pad_ProcessReportFn = (pad: number, report: number, size: number) -> ()
-- rac1.player.update_motion_input (Hero_UpdateMotionInput) void(): The stick read into the hero, early in his update each tick.
type Hero_UpdateMotionInputFn = () -> ()
-- rac1.player.turn_to_heading (Hero_TurnToHeading) void(i32,f32,f32,f32): Eases the hero's facing toward his move yaw.
type Hero_TurnToHeadingFn = (mode: number, accel: number, damping: number, limit: number) -> ()
-- rac1.player.set_planar_velocity (Hero_SetPlanarVelocity) void(f32): The hero's velocity at his ground speed along an angle; an angle above pi means his facing.
type Hero_SetPlanarVelocityFn = (angle: number) -> ()
-- rac1.camera.follow.apply_overrides (FollowCamera_ApplyOverrides) void(u32): The follow camera's per-tick requests from the hero's state; the camera moby's update calls it before it places the eye.
type FollowCamera_ApplyOverridesFn = (camera: number) -> ()
-- rac1.player.advance_animation (Hero_AdvanceAnimation) void(): Ratchet's animation moved on by his animation speed, once a tick after his state's update.
type Hero_AdvanceAnimationFn = () -> ()
-- rac1.player.update (Hero_Update) void(): The hero's whole update, once a tick from the level loop (coordinate_hero_frame_update, and its copies update_hero_frame and HeroL03_FrameUpdate in the other families of levels: one hook point): his animation's advance, the stick, his state machine and movement (Hero_UpdateMotionInput), ledges and rails, his state's transitions, his body's easing, his moby and matrices, what he holds and his drawing; it fades out when he leaves the world's bounds. A replacement that does not call the original moves him by itself and shows him with openrac_api.hero_set_pose.
type Hero_UpdateFn = () -> ()
-- rac1.item.give (Item_Give) void(i32,i32): Gives the player item id (GiveItem): sets its owned and obtained bytes, shows its banner, gives its starting ammo, marks it bought in the vendor's stock and adds it to the quick select; equip non-zero also puts it in hand. Every item the game gives goes through it but the Persuader's.
type Item_GiveFn = (id: number, equip: number) -> ()
-- rac1.planet.unlock (Planet_Unlock) void(i32): Unlocks a planet's coordinates (UnlockPlanet): its flag (one byte per level), the galaxy list, and its banner unless it is the planet the player is on.
type Planet_UnlockFn = (planet: number) -> ()
-- rac1.help.request (Help_Request) i32(i32,i32): Queues help message message in the help window's slot (Help_Request): 1 when queued, 0 when it cannot be. Every tutorial and hint of the levels comes through it. A mod may replace the message: call the original with the new id and the same slot, and return its result. The id must be in the level's table; one that is not shows nothing, though the result is still 1.
type Help_RequestFn = (message: number, slot: number) -> number
-- rac1.ship.init_transition (Ship_InitTransition) void(i32): Puts the hero in the ship for a landing or take-off (initialize_level_transition_with_audio): the ship's records, the sound, and the chunks to load. On Orxon its choice of chunks goes by whether the O2 Mask is owned.
type Ship_InitTransitionFn = (mode: number) -> ()
-- rac1.vendor.init_level_stock (Vendor_InitLevelStock) void(): The vendor's stock at each level start (VendorStockLevelInit): gives the Bomb Glove while the player has none, keeps the stock's known items and adds the level's new weapon.
type Vendor_InitLevelStockFn = () -> ()
-- rac1.vendor.build_item_list (Vendor_BuildItemList) void(i32): The vendor menu's list (VendorBuildItemList), from the stock and the items owned: each time the menu opens and after each purchase. skip_unflagged leaves out what is for sale (the menu opened from the pause screen).
type Vendor_BuildItemListFn = (skip_unflagged: number) -> ()
-- rac1.gold_bolt.count_collected (GoldBolts_CountCollected) i32(): The gold bolts collected, at most 40 (count_nonzero_entries_up_to_40): what the pause screen shows; the unspent ones are this less 4 per gold weapon.
type GoldBolts_CountCollectedFn = () -> number
-- rac1.player.take_damage (Hero_TakeDamage) void(i32): Takes hit points off the hero's health (Hero_TakeDamage): at most one a call, none for 0, then the HUD's health bank. Every hit the hero takes goes through it but the instant kills (falls, crushers), which set his health to 0.
type Hero_TakeDamageFn = (amount: number) -> ()
-- rac1.combat.get_hit (Moby_GetHitMessage) u32(u32,i32,i32): The hit pending on moby (MobyGetHitMessage): the record of the last hit posted to it (+0x20 the attacker, +0x24 the flags, +0x2C the damage, an f32) when its flags match mask, else 0, dropping the hit unless keep. How the hero and every enemy read the hits they take, each tick, so a hit may be read more than once.
type Moby_GetHitMessageFn = (moby: number, mask: number, keep: number) -> number
-- rac1.weapon.take_ammo (Weapon_TakeAmmo) i32(i32,i32): Takes amount of ammo from item for a shot (TakeAmmo; -1 is the item in hand): 1 when taken, 0 when there is too little. An item with no ammo limit takes none and gives 1.
type Weapon_TakeAmmoFn = (item: number, amount: number) -> number
-- rac1.weapon.blaster.pick_target (Weapon_Blaster_PickTarget) u32(i32,u32,u32,u32): Chooses the Blaster's auto-aim target for a shot from from (select_blaster_auto_aim_target; from a Vec4, yaw and pitch f32s, all addresses): the nearest targetable creature (Moby flags 0x1000) within 20 units whose aim point is within about 9 degrees of the heading yaw/pitch and in sight from the camera and from from (ignore: the moby the sight test passes over). Writes the pitch toward it, and the yaw when within 10 degrees, and returns it; 0 for none.
type Weapon_Blaster_PickTargetFn = (ignore: number, from: number, yaw: number, pitch: number) -> number
-- rac1.weapon.ryno.pick_target (Weapon_Ryno_PickTarget) u32(u32,u32,u32,f32,f32,f32): Chooses a R.Y.N.O. missile's target (select_ryno_target): the creature with a target record, of class type 5, within max_distance across of pos (a Vec4 address) and max_yaw / max_pitch of the aim angles (aim, f32s at +4 pitch and +8 yaw), the best by angle and distance, in sight; skip is the seven mobys the salvo has already (0: only the ones drawn last frame). Returns the moby, 0 for none.
type Weapon_Ryno_PickTargetFn = (pos: number, aim: number, skip: number, max_yaw: number, max_pitch: number, max_distance: number) -> number
-- rac1.weapon.gold_devastator.pick_target (Weapon_GoldDevastator_PickTarget) void(u32,u32,u32): Chooses the gold Devastator missile's target (select_gold_devastator_missile_target): the creature within 40 units of the missile nearest its heading, in a cone that widens with the weapon's level, in sight, not skip; writes it into the missile's data (data, its pvars).
type Weapon_GoldDevastator_PickTargetFn = (missile: number, data: number, skip: number) -> ()
-- rac1.weapon.drone.pick_target (Weapon_Drone_PickTarget) u32(u32,u32): Chooses a drone's target (select_nearest_drone_target): the nearest moby of class type 5, 7 or 8 to from (a Vec4 address), within 4, 5.3 or 6 units by type, not one of the nine in skip, not held by the Suck Cannon. Returns the moby, 0 for none.
type Weapon_Drone_PickTargetFn = (from: number, skip: number) -> number
-- rac1.moby.record_death (Moby_RecordDeath) void(u32,i32,i32): Records a placed moby's death or a crate's break (SetDeathBits): its save id's killed bits (none for a save id below 0), its mission, then drops its bolts: about the s16 at +0xB4 (or what a tallied source has left of +0xB6), which it then clears.
type Moby_RecordDeathFn = (moby: number, flags: number, index: number) -> ()
-- rac1.level.load_gameplay (Level_LoadGameplay) u32(i32): Loads a level's gameplay file into the level heap (LoadLevelGameplay), once per level start: the settings, the placed mobys and their pvars, the spare moby pool, the paths and the rest; returns the heap cursor. After it, every placed moby exists and none has run.
type Level_LoadGameplayFn = (full: number) -> number
-- rac1.player.approach_speed (Hero_ApproachSpeed) void(f32,f32): Eases the hero's ground speed (+0x194, the speed Hero_SetPlanarVelocity moves him at) toward his target speed (+0x190) by up when below it and by down when above, each tick he moves on foot, in every level.
type Hero_ApproachSpeedFn = (up: number, down: number) -> ()
-- rac1.ship.travel_to (Ship_TravelTo) void(i32): The ship's travel from the planet select (ShipTravelTo), once its menu closes: to the planet it is on (dest the level now), the landing again, as backing out of the select does; to another, the game saved to the card and the ship's flight out of the level, whose loop then ends and flies to dest. After the take-off; a level's only way to another planet by ship.
type Ship_TravelToFn = (dest: number) -> ()
-- rac1.moby.collect_bolt (Moby_CollectBolt) void(u32): Collects a bolt (collect_bolt), called by the bolt update (classes 13 to 16) once the bolt reaches the hero: adds its value (1, or 5 / 20 / 50 for classes 14 / 15 / 16) to the bolt count, the level's total and its source's stats, shows the bolt counter and makes two sparkles at it. The bolt update then deletes the bolt (a placed one marked taken) whether or not this ran.
type Moby_CollectBoltFn = (bolt: number) -> ()
-- rac1.menu.item_grid.update (Menu_ItemGrid_Update) i32(u32): Moves the pause menu item grid's focus and takes its selection (update_menu_grid_selection), each tick the grid is open. Returns the menu's action.
type Menu_ItemGrid_UpdateFn = (grid: number) -> number
-- rac1.menu.item_grid.draw (Menu_ItemGrid_Draw) i32(u32): Draws the pause menu item grid (draw_menu_item_grid). Returns the render-pass flags the menu passes on.
type Menu_ItemGrid_DrawFn = (grid: number) -> number
-- rac1.menu.item_slots.update (Menu_ItemSlots_Update) i32(u32): Puts the highlighted item in one of the quick select's eight slots (update_menu_item_slots), in the pause menu's quick select editor.
type Menu_ItemSlots_UpdateFn = (list: number) -> number
-- rac1.menu.quick_select.draw (Menu_QuickSelect_Draw) i32(u32): Draws the pause menu's quick select ring (draw_pause_ring). Returns the render-pass flags.
type Menu_QuickSelect_DrawFn = (screen: number) -> number
-- rac1.menu.quick_select.load (Menu_QuickSelect_Load) i32(u32): Copies the eight saved quick select items into the pause menu's editor (load_selection_list).
type Menu_QuickSelect_LoadFn = (list: number) -> number
-- rac1.menu.quick_select.store (Menu_QuickSelect_Store) i32(u32): Copies the editor's eight quick select items (+0x30 of screen) back to the saved quick select (pause_stage_sprite_lists).
type Menu_QuickSelect_StoreFn = (screen: number) -> number
-- rac1.menu.item_text.draw (Menu_ItemText_Draw) i32(u32): Draws a menu text label from its configuration (render_configured_text_label): the selected item's name and description among others.
type Menu_ItemText_DrawFn = (label: number) -> number
-- rac1.menu.item_ammo.draw (Menu_ItemAmmo_Draw) i32(i32): Draws the selected item's ammo panel in the pause menu (draw_selected_item_ammo).
type Menu_ItemAmmo_DrawFn = (screen: number) -> number
-- rac1.menu.preview.bind (Menu_Preview_Bind) i32(u32): Binds the selected item, and what it carries, to the pause menu's preview (update_item_preview_binding).
type Menu_Preview_BindFn = (preview: number) -> number
-- rac1.menu.preview.update (Menu_Preview_Update) i32(u32): Makes or replaces the moby of the pause menu's item preview (update_item_preview_moby).
type Menu_Preview_UpdateFn = (screen: number) -> number
-- rac1.menu.preview.draw_available (Menu_Preview_DrawAvailable) i32(u32): Draws the preview mobys of the owned, selected item (draw_available_item_preview_mobys). Returns the render-pass flags.
type Menu_Preview_DrawAvailableFn = (screen: number) -> number
-- rac1.menu.preview.draw_selected (Menu_Preview_DrawSelected) i32(u32): Draws the selected item's preview, or the message for an item not owned (draw_item_preview_screen).
type Menu_Preview_DrawSelectedFn = (screen: number) -> number
-- rac1.menu.equipped_preview.update (Menu_EquippedPreview_Update) i32(u32): Loads the preview of the gadget or weapon in hand (LoadHandGadget).
type Menu_EquippedPreview_UpdateFn = (hand: number) -> number
-- rac1.menu.equipped_preview.draw (Menu_EquippedPreview_Draw) i32(u32): Draws the pause menu's preview of the hero and what he holds (draw_menu_preview_objects).
type Menu_EquippedPreview_DrawFn = (screen: number) -> number
-- rac1.hud.quick_select.init (Hud_QuickSelect_Init) void(u32): Sets up the quick select's eight-slot selector in play (initialize_eight_slot_hud_selector).
type Hud_QuickSelect_InitFn = (selector: number) -> ()
-- rac1.hud.quick_select.update (Hud_QuickSelect_Update) void(u32): The quick select in play, each tick (update_hud_item_selector_selection_and_visibility): its focus, whether it shows, and the item chosen.
type Hud_QuickSelect_UpdateFn = (selector: number) -> ()
-- rac1.hud.quick_select.draw (Hud_QuickSelect_Draw) i32(u32): Draws the quick select's item icons in play (draw_hud_item_selector_panel).
type Hud_QuickSelect_DrawFn = (panel: number) -> number
-- rac1.vendor.menu_update (Vendor_MenuUpdate) void(): The vendor's purchase menu, each tick it is open (update_vendor_purchase): buying items and ammo.
type Vendor_MenuUpdateFn = () -> ()
-- rac1.vendor.initialize_selected (Vendor_InitializeSelected) void(): Sets up the mobys and text of the vendor's selected row (initialize_vendor_selected_item_mobys).
type Vendor_InitializeSelectedFn = () -> ()
-- rac1.ammo.choose_drop (Ammo_ChooseDrop) i32(u32,u32): Chooses the ammo a dying moby or a broken crate drops (ChooseDropItem): writes the item to out_item and returns how many pickups.
type Ammo_ChooseDropFn = (moby: number, out_item: number) -> number
-- rac1.ammo.spawn_drop (Ammo_SpawnDrop) u32(u32,i32,i32,i32): Makes an ammo pickup moby of item at pos (spawn_on_path); amount -1 takes the item's own. Returns the moby, or 0.
type Ammo_SpawnDropFn = (pos: number, item: number, amount: number, flags: number) -> number
-- rac1.save.prepare (Save_Prepare) void(i32,i32): Writes the game's state into a save and starts a full memory card write (prepare_save_game).
type Save_PrepareFn = (buffer: number, slot: number) -> ()
-- rac1.save.request_autosave (Save_RequestAutosave) i32(i32,i32): Writes the save's packets and asks for their memory card update (memcard_Save), as an autosave does.
type Save_RequestAutosaveFn = (slot: number, flags: number) -> number
-- rac1.save.restore (Save_Restore) void(u32): Restores a whole save from memory (memcard_RestoreGame); a new game's default state goes through it too. The port keeps the player's options around it (rac1/host/options.c).
type Save_RestoreFn = (save: number) -> ()
-- rac1.save.restore_data (Save_RestoreData) i32(u32,i32,u32): Restores one checked save packet (memcard_RestoreData); loading a file calls it directly. Returns non-zero when it took the packet.
type Save_RestoreDataFn = (src: number, slot: number, table: number) -> number
-- rac1.save.new_game (Save_NewGame) void(): A new game (NewGameInit): the disc's default state, and level 0. The port's --level N runs around it (rac1/host/boot.c).
type Save_NewGameFn = () -> ()
-- rac1.save.new_game_plus (Save_NewGamePlus) void(i32): Challenge mode's start (load_level_zero_preserving_progress): the game reset to level 0 with the progress it carries kept.
type Save_NewGamePlusFn = (slot: number) -> ()
-- rac1.save.serialize (Save_Serialize) void(u32): Writes the whole save into out (memcard_MakeWholeSave), with no memory card access.
type Save_SerializeFn = (out: number) -> ()
-- rac1.save.update_state (Save_UpdateState) void(): The memory card's state machine, each tick (memcard_update_state): saves and loads go through it.
type Save_UpdateStateFn = () -> ()
-- rac1.text.msg_string (msg_string) i32(i32): Resolves a game message id to its text. A mod may substitute the randomized reward name while the game's reward banner is drawn.
type msg_stringFn = (id: number) -> number
-- rac1.vendor.open_menu (Vendor_OpenMenu) void(u32): Opens the vendor purchase menu, including the Gadgetron PDA remote vendor when moby is zero.
type Vendor_OpenMenuFn = (moby: number) -> ()
-- rac1.gold_bolt.count_unspent (GoldBolts_CountUnspent) i32(): Unspent gold bolts available for purchases; retail subtracts four per purchased gold weapon. Mods may separate purchases from gold weapon ownership.
type GoldBolts_CountUnspentFn = () -> number
-- rac1.omni.damage.build_hit (Damage_BuildHit) void(u32,u32,u32,f32,u32): hit_desc_build: fills a hit descriptor (0x24+ bytes) for a hit on an enemy: the 16-byte direction vector at +0, attacker moby +0x10, mask +0x14, damage f32 +0x1c, +0x20 = 1. Every attack that hurts an enemy builds one (the wrench on the stack right before its swing sweep), so a hook that calls the original with another damage changes what is dealt. Checked against the wrench update's call (a0 = descriptor on the stack, a1 = attacker moby, a2 = mask, a3 = vec4 direction, f12 = damage). Every level.
type Damage_BuildHitFn = (desc: number, attacker: number, mask: number, damage: number, dir: number) -> ()
-- rac1.omni.damage.hit_victim (Damage_HitVictim) void(u32,u32): hit_ring_write: posts a hit descriptor on the victim moby into the 64-entry hit queue at 0x178100 (stride 0x40) unless the victim already holds a stronger hit this tick (victim byte +0xa4 = queue slot); the victim reads it in MobyGetHitMessage (rac1.combat.get_hit). To hurt an enemy from a mod: build a descriptor with omni.with_stack and the build_hit function, then call this. a0 = victim, a1 = descriptor (asm of the prologue). Every level.
type Damage_HitVictimFn = (victim: number, desc: number) -> ()
-- rac1.omni.wrench.swing (Wrench_SwingSweep) u32(u32,u32,u32,u32,u32,u32,i32): The wrench swing sweep: five segment casts between the previous and the current wrench joint poses (four vec4 pointers into the hero struct +0x9f0, +0xa00, +0xa10, +0xa20), owner = the word at hero +0x2080, attack = the hit descriptor built just before (damage at +0x1c), steps = 5. Returns 1 when something was hit. Only caller: the class 71 update. Argument registers a0..a3, t0, t1, t2 checked in the caller's asm. Every level.
type Wrench_SwingSweepFn = (prev_a: number, prev_b: number, cur_a: number, cur_b: number, owner: number, attack: number, steps: number) -> number
-- rac1.omni.wrench.throw (Wrench_ThrowRelease) void(): Comet-Strike release: aims and launches the thrown wrench (sets the wrench byte +0x20 = 10 and the byte at 0x1403fa). No arguments (the callers set none for it). Callers: the try-fire dispatcher and 0x217550 (Veldin). Every level.
type Wrench_ThrowReleaseFn = () -> ()
-- rac1.moby.wrench.update (Wrench_Update) void(u32): Per-tick update of the held Omniwrench (moby class 71): combo state, swing damage literals, calls the swing sweep and the hit descriptor builder. Every level.
type Wrench_UpdateFn = (moby: number) -> ()
-- rac1.moby.suck_cannon.update (Weapon_SuckCannon_Update) void(u32): Per-tick update of the held Suck Cannon (moby class 849, the class table's update function; a mod reads omni.weapon.* fields and the hero state). Every level.
type Weapon_SuckCannon_UpdateFn = (moby: number) -> ()
-- rac1.moby.moby192.update (Weapon_BombGlove_Update) void(u32): Per-tick update of the held Bomb Glove (moby class 192, the class table's update function; a mod reads omni.weapon.* fields and the hero state). Every level.
type Weapon_BombGlove_UpdateFn = (moby: number) -> ()
-- rac1.omni.weapon.devastator.update (Weapon_Devastator_Update) void(u32): Per-tick update of the held Devastator (moby class 157, the class table's update function; a mod reads omni.weapon.* fields and the hero state). Every level.
type Weapon_Devastator_UpdateFn = (moby: number) -> ()
-- rac1.moby.moby163.update (Weapon_Visibomb_Update) void(u32): Per-tick update of the held Visibomb Gun (moby class 163, the class table's update function; a mod reads omni.weapon.* fields and the hero state). Every level.
type Weapon_Visibomb_UpdateFn = (moby: number) -> ()
-- rac1.moby.moby175.update (Weapon_Taunter_Update) void(u32): Per-tick update of the held Taunter (moby class 175, the class table's update function; a mod reads omni.weapon.* fields and the hero state). Every level.
type Weapon_Taunter_UpdateFn = (moby: number) -> ()
-- rac1.omni.weapon.blaster.update (Weapon_Blaster_Update) void(u32): Per-tick update of the held Blaster (moby class 168, the class table's update function; a mod reads omni.weapon.* fields and the hero state). Every level.
type Weapon_Blaster_UpdateFn = (moby: number) -> ()
-- rac1.moby.pyrocitor.update (Weapon_Pyrocitor_Update) void(u32): Per-tick update of the held Pyrocitor (moby class 176, the class table's update function; a mod reads omni.weapon.* fields and the hero state). Every level.
type Weapon_Pyrocitor_UpdateFn = (moby: number) -> ()
-- rac1.moby.mine_glove.update (Weapon_MineGlove_Update) void(u32): Per-tick update of the held Mine Glove (moby class 190, the class table's update function; a mod reads omni.weapon.* fields and the hero state). Every level.
type Weapon_MineGlove_UpdateFn = (moby: number) -> ()
-- rac1.moby.moby180.update (Weapon_Walloper_Update) void(u32): Per-tick update of the held Walloper (moby class 180, the class table's update function; a mod reads omni.weapon.* fields and the hero state). Every level.
type Weapon_Walloper_UpdateFn = (moby: number) -> ()
-- rac1.omni.weapon.tesla_claw.update (Weapon_TeslaClaw_Update) void(u32): Per-tick update of the held Tesla Claw (moby class 177, the class table's update function; a mod reads omni.weapon.* fields and the hero state). Every level.
type Weapon_TeslaClaw_UpdateFn = (moby: number) -> ()
-- rac1.moby.carrier.update (Weapon_GloveOfDoom_Update) void(u32): Per-tick update of the held Glove of Doom (moby class 229, the class table's update function; a mod reads omni.weapon.* fields and the hero state). Every level.
type Weapon_GloveOfDoom_UpdateFn = (moby: number) -> ()
-- rac1.moby.morphoray.update (Weapon_MorphORay_Update) void(u32): Per-tick update of the held Morph-o-Ray (moby class 185, the class table's update function; a mod reads omni.weapon.* fields and the hero state). Every level.
type Weapon_MorphORay_UpdateFn = (moby: number) -> ()
-- rac1.moby.ryno.update (Weapon_Ryno_Update) void(u32): Per-tick update of the held R.Y.N.O. (moby class 454, the class table's update function; a mod reads omni.weapon.* fields and the hero state). Every level.
type Weapon_Ryno_UpdateFn = (moby: number) -> ()
-- rac1.moby.decoy_glove.update (Weapon_Decoy_Update) void(u32): Per-tick update of the held Decoy Glove (moby class 562, the class table's update function; a mod reads omni.weapon.* fields and the hero state). Every level.
type Weapon_Decoy_UpdateFn = (moby: number) -> ()
-- rac1.moby.ammo_pickup.update (Ammo_Pickup) void(u32): Per-tick update of an ammo pickup moby (Veldin 0x2c4d68, names row func_L00_002C6720; classes 204 213 214 222 223 225 226 1006 1438 1447 1449, the broken crates' ammo): physics in states 1/3/4, and in the waiting state a jump-table case INLINES the pickup (distance to the hero, AddAmmo, banner, state 2). Every ammo the hero collects by walking into a pickup is given inside this call, so a mod that wraps `original` sees AddAmmo (rac1.omni.ammo.add) run inside it and can tell a pickup from a vendor purchase. The moby's pvar (moby+0x78) holds pvar[0] = amount, pvar[2] = item id, readable before `original`. Stage AP1: this id used to be the collect helper 0x2c5590, which this path never calls (see rac1.omni.ammo.collect). Every level.
type Ammo_PickupFn = (moby: number) -> ()
-- rac1.omni.ammo.add (Ammo_Add) i32(i32,i32): AddAmmo: adds amount to the ammo int of item (0x13d428 + item * 4) and caps it at the max ammo of the price row; returns the overflow. Shared by pickups, the vendor and UnlockGadget. Every level.
type Ammo_AddFn = (item: number, amount: number) -> number
-- rac1.omni.weapon.select (Hero_ItemRequestApply) void(u32): Applies the requested item (0x141408 and the kind words) for hero item slot `slot`; the equip path of Square (wrench), Circle (last weapon) and the quick-select commit. Decomp name hero_item_request_apply, names tsv label UpdateWrenchSelected; 2216 bytes, callers 0x210290 and 0x229750 (Veldin). Not in the code of Rilgar (5) and Kalebo III (16): no hook there. Argument a0 = slot checked in the caller's asm and the Ghidra C.
type Hero_ItemRequestApplyFn = (slot: number) -> ()
-- rac1.omni.damage.resolve (Damage_Resolve) u32(u32,u32,u32,u32,u32,u32,u32,u32): The shared hit resolver (Veldin FUN_0025a088, names row hit_knockback): every enemy class calls it once per tick from its prestep with the hit entry that rac1.combat.get_hit returned. a0 = the victim moby, a1 = the hit queue entry (0 = none; +0x20 attacker moby, +0x2c strength), a2 = the victim's component block (pvar +0x20: the health float, +8 the component byte), a3 = 0 in every caller read, t0 = u32 out (status: 0, or 1 = no usable hit), t1 = f32 out (the STRENGTH the class subtracts from its health; may be 0 = no pointer), t2 = u32 out (-1 or untouched, may be 0), t3 = mode (4 = take it from the component byte). The return value is the reaction class (0 nothing, 0xb, 0xd, jump-table cases), NOT the strength: the strength is written to *t1 (= entry +0x2c, which the resolver sets from the attacker table for Blaster classes 0x131 and 0xa8). A mod scales damage dealt to enemies by calling original and then multiplying the f32 at strength_out (when it is not 0) and entry +0x2c; it reads the victim's health first through the pvars/structs (enemy.health). Signature checked in the asm prologue (a0..a3, t0..t3 stored/used) and the Ghidra C (8 parameters) and a caller (toad prestep FUN_002d4b08: a0 victim, a1 entry, a2 pvar+0x20, a3 0, t0 &status, t1 &strength, t2 0, t3 4). Every level.
type Damage_ResolveFn = (victim: number, entry: number, component: number, arg3: number, status_out: number, strength_out: number, extra_out: number, mode: number) -> number
-- rac1.omni.weapon.flame.create (Pyrocitor_FlameCreate) u32(u32,u32,u8,f32): The Pyrocitor flame effect creator (names tsv PartType12Spawn; shared with the flame effect of other callers): f12 = the flame reach / life float, a0 = position vec4 address, a1 = velocity vec4 address, a2 = flags byte (bit 2 always set, bit 0 = lead flame vs trailing). The held update calls it 2 leading and 2 trailing times per tick. A mod calls original again with its own vel vector (omni.with_stack) for extra flames. Argument registers checked by argscan and the caller at 0x2b7880 (Ghidra C: FUN_0026abc0(float, vec*, vec*, byte)). Every level.
type Pyrocitor_FlameCreateFn = (pos: number, vel: number, flags: number, range: number) -> number
-- rac1.omni.weapon.bomb_glove.fire (Weapon_BombGlove_Fire) void(u32,u32,u32): Launches the held bomb (FUN_002ac980, state 3 of the held update 0x2c2070 once per throw, then the held bomb pointer is cleared): a0 = a stack vec (aim), a1 = the bomb moby (spawned by FUN_002ac818), a2 = its pvar (moby +0x78). Every level.
type Weapon_BombGlove_FireFn = (pos_ptr: number, bomb: number, pvar: number) -> ()
-- rac1.omni.weapon.mine_glove.fire (Weapon_MineGlove_Fire) void(u32,u32,u32): Launches the held mine (FUN_002a99b0, state 3 of the held update 0x2c1478 once per throw): a0 = a stack vec (aim), a1 = the mine moby (class 74, created by FUN_002a9878), a2 = its pvar (moby +0x78). Every level.
type Weapon_MineGlove_FireFn = (pos_ptr: number, mine: number, pvar: number) -> ()
-- rac1.omni.weapon.glove_of_doom.fire (Weapon_GloveOfDoom_Fire) void(u32,u32,u32): Launches the held Glove of Doom capsule (FUN_002c7c98, once per shot; the caller then clears the held pointer): a0 = hero + 0x40 vec, a1 = the capsule moby (class 230, created by FUN_002c7bc0), a2 = its pvar (moby +0x78). Every level.
type Weapon_GloveOfDoom_FireFn = (pos_ptr: number, capsule: number, pvar: number) -> ()
-- rac1.omni.weapon.devastator.fire (Weapon_Devastator_Fire) u32(u32,u32,u32,f32,f32,f32,f32,f32): Creates a Devastator rocket (FUN_002af618, class 153; once per rocket, two call sites in the held update 0x2b1aa8): a0 = word stored in the rocket pvar +0x10, a1 = spawn position vec4 address, a2 = the owner moby (its component is read), f12 = float stored at the rocket pvar +0x2c, f13 and f14 = floats kept in the creator, f15 = stored at moby +0x48, f16 = stored at moby +0x44 (meaning of the floats [?]); returns the rocket moby. Register reads checked by argscan and the prologue asm (a0, a1, a2, f12..f16; Ghidra's 8 parameters are an artefact). Every level.
type Weapon_Devastator_FireFn = (pvar_arg: number, pos: number, owner: number, f0: number, f1: number, f2: number, f3: number, f4: number) -> number
-- rac1.omni.weapon.visibomb.fire (Weapon_Visibomb_Fire) u32(u32,u32,f32,f32): Creates the Visibomb missile (FUN_002b5280, class 172; once per shot from the held update 0x2b2a00): f12, f13 = floats (speed / aim [?]), a0 = the owner moby, a1 = a vec4 address (launch direction); returns the missile moby (stored in the held pvar word 1). Registers by argscan. Every level.
type Weapon_Visibomb_FireFn = (owner: number, dir: number, f0: number, f1: number) -> number
-- rac1.omni.weapon.blaster.fire (Weapon_Blaster_Fire) u32(u32,u32,u32,f32,f32,f32,f32): Creates a Blaster shot (FUN_002ca918, class 305 = 0x131, the attacker class whose strength comes from the table at gp -0x6bc0; once per shot from the held update 0x2b4350): f12..f15 = four floats (shot speed / direction components [?]), a0 = the word at 0x1413d0, a1 = a vec address, a2 = a moby pointer; returns the shot moby. Registers by argscan and the caller (7 parameters in the Ghidra C). Every level.
type Weapon_Blaster_FireFn = (iarg: number, vec: number, target: number, f0: number, f1: number, f2: number, f3: number) -> number
-- rac1.omni.moby.create (moby_create) u32(u32): Retail CreateMoby (Veldin 0x24e448): allocates a moby of a class with its pvar block, returns the moby (0 when full). The class init then runs on its first update. Every level. Every dynamic spawn of the game (projectiles, sparks, glow spheres, debris) goes through it; placed mobies of a level do not (use level_loaded + mobys). Hot: hundreds of calls per second in a fight, so a mod filters by class first and returns. A hook must not spawn the same class from inside it.
type moby_createFn = (class: number) -> number
-- rac1.moby.hero_bomb.update (projectile_bomb_update) void(u32): Bomb Glove bomb (class 121) per-tick update (Veldin 0x2ad4d8, 6.3 KB). Every level.
type projectile_bomb_updateFn = (moby: number) -> ()
-- rac1.moby.mine.update (projectile_mine_update) void(u32): Mine Glove mine (class 74) per-tick update (Veldin 0x2aa018). Every level.
type projectile_mine_updateFn = (moby: number) -> ()
-- rac1.moby.moby305.update (projectile_blaster_shot_update) void(u32): Blaster shot (class 305) per-tick update (Veldin 0x2cadc0): steers to the point in pvar+0, moves 0.8 u/tick along yaw/pitch, ray test, gold bounce. Every level.
type projectile_blaster_shot_updateFn = (moby: number) -> ()
-- rac1.moby.rocket_steer.update (projectile_ryno_rocket_update) void(u32): R.Y.N.O. rocket (class 457) per-tick update (Veldin 0x2ccb98): homes on the moby in pvar+0x28. Every level.
type projectile_ryno_rocket_updateFn = (moby: number) -> ()
-- rac1.moby.doom_bot.update (projectile_doom_agent_update) void(u32): Glove of Doom agent (class 186) per-tick update (Veldin 0x2bf950): state machine, state 0xb = explode. Every level.
type projectile_doom_agent_updateFn = (moby: number) -> ()
-- rac1.moby.bomb_230.update (projectile_doom_capsule_update) void(u32): Glove of Doom capsule (class 230) per-tick update (Veldin 0x2c8390). Every level.
type projectile_doom_capsule_updateFn = (moby: number) -> ()
-- rac1.moby.visibomb_missile.update (projectile_visibomb_update) void(u32): Visibomb missile (class 172) per-tick update (Veldin 0x2b5ae8; player-steered missile). Every level.
type projectile_visibomb_updateFn = (moby: number) -> ()
-- rac1.moby.missile.update (projectile_devastator_rocket_update) void(u32): Devastator rocket (class 153) per-tick update (Veldin 0x2afd48): steers to its target, gold bounces 3 times. Every level.
type projectile_devastator_rocket_updateFn = (moby: number) -> ()
-- rac1.omni.collide.segment (collide_segment) u32(u32,u32,u32,u32,u32): Retail seg_collide (Veldin 0x1efbf0): segment start..end vs mobys and terrain; a3 = moby to ignore, t0 = hit descriptor (0 = none; when set and the hit moby takes hits the hit is posted into the hit ring). Returns 1 on a hit; result block at the level block RES (Veldin 0x173e40): +0x18 hit moby (0 = terrain), +0x1c record word, +0x20 contact point vec4, +0x40 surface normal vec4. Hot function (every projectile, the camera, the hero). Every level.
type collide_segmentFn = (start: number, end: number, mask: number, self: number, attack: number) -> number
-- rac1.omni.collide.sphere_mobys (collide_sphere_mobys) u32(f32,u32,u32,u32,u32): Retail sphere_list_mobys (Veldin 0x1f27e8): list the mobys within radius of pos (mask 0x10 = hittable); the list lands at 0x177f00 (Veldin), returns the count. Blasts call it right before blast.apply. Every level.
type collide_sphere_mobysFn = (radius: number, pos: number, mask: number, self: number, filter: number) -> number
-- rac1.omni.blast.apply (blast_apply) void(u32,u32,u32,u32,u32,u32,u32,u32,f32,f32,f32): Retail apply_blast_damage (Veldin 0x25a608): posts one hit (hit_desc_build + hit_ring_write) per listed moby; attacker = the projectile (its class is the weapon). Every level.
type blast_applyFn = (attacker: number, pos: number, list: number, count: number, exclude: number, mask: number, cat: number, sub: number, strength: number, hscale: number, vimpulse: number) -> ()
-- rac1.omni.hero.items_attach (HeroItems_Attach) void(): Retail HeroItemsAttach (Veldin 0x20f0c8, names row HeroItemsAttach, shared code, once per tick, no arguments): glues every item the hero holds to the hero. For each hero item slot (table 0x1403e0, stride 0x50) it copies the attach matrix of the item's attach point (the Blaster and other weapons: the right hand) into the held moby: position +0x10, basis rows +0xc0/0xd0/0xe0, pitch/yaw, sets moby flags |= 6 (not scheduled, no transform) and copies the light words from the hero. Hook it after `original` to place or update extra mobies that follow the hero (read omni.hero.held_moby; the held weapon is already in its final place for this tick).
type HeroItems_AttachFn = () -> ()
-- rac1.omni.ammo.collect (Ammo_Collect) u32(u32): The ammo pickup collect helper (Veldin 0x2c5590, names row func_L00_002C6F48, 480 bytes), the second way an ammo pickup is collected: called by the code that scans the mobys near the hero or a blast (Veldin callers 0x2a7c68 and 0x2deb88), NOT by the pickup moby's own update (rac1.omni.ammo.pickup inlines the same job). pvar[0] = amount, pvar[2] = item id; adds it with AddAmmo, shows the banner, returns 1 when collected. A mod that changes pickup ammo wraps both ids the same way. Stage AP1: this was rac1.omni.ammo.pickup before. Every level.
type Ammo_CollectFn = (moby: number) -> number
-- rac1.omni.hud.health_draw (Hud_HealthDraw) u32(u32): Draws the HUD's nanotech meter (the health orbs and their bar) for its HUD element and returns the word at element +0x58. The meter fades in and out in steps 0..8 (struct hud_health: fade_bar at +0x70, fade_orbs at +0x71); it shows 100 ticks after the health changes (180 at a level start) and stays up at 1 orb. A mod that draws its own health replaces it: skip the original and return the word at +0x58 (hud_health.result). Every level.
type Hud_HealthDrawFn = (element: number) -> number
-- rac1.moby.<class>.update (experimental): (moby: number) -> (), or () -> () where it gets no moby.
type MobyUpdateFn = (moby: number) -> ()

declare openrac: {
    game: string,
    version: "pal" | "ntsc",
    platform: string,
    api: string,
    log: (...any) -> (),
    warn: (...any) -> (),
    setting: (key: string) -> any,
    hook: (name: HookPoint, fn: (original: (...number) -> ...number, ...number) -> ...number) -> (),
    before: (name: HookPoint, fn: (...number) -> ()) -> (),
    after: (name: HookPoint, fn: (...number) -> ()) -> (),
    on_frame: (fn: () -> ()) -> (),
    on_pad: (fn: (port: number, report: buffer) -> ()) -> (),
    read: (kind: MemoryType, address: number) -> number,
    write: (kind: MemoryType, address: number, value: number) -> (),
    fields: Fields,
    -- interface 1.2: the keyboard and mouse; a bind is a name of openrac/keys.h ("KeyW", "MouseLeft", "WheelUp")
    key: (bind: string) -> boolean,
    pressed: (bind: string) -> boolean,
    mouse: () -> (number, number, number, number),
    window: () -> (boolean, boolean, boolean),
    -- interface 1.3: the cursor over the game's picture, 0..1 each way (x * 512, y * 416 the game's 2D pixel), and whether it is over it
    pointer: () -> (number, number, boolean),
    take_input: (...("keyboard" | "mouse")) -> (),
    capture_mouse: (capture: boolean) -> (),
    -- interface 1.13: the on-screen pad's action buttons (MODS.md, "Touch controls")
    touch_define: (json: string) -> boolean,
    touch_icon: (name: string, svg: string) -> boolean,
    touch_push: (context: string?) -> (),
    touch_hint: (hint: string, on: boolean) -> (),
    -- interface 1.15: the mod's own settings set (for the run and in the launcher's list), and its changes heard
    set_setting: (key: string, value: any) -> boolean,
    on_settings: (fn: () -> ()) -> (),
    -- experimental: a moby's pvars by name, from the behaviour catalogue
    pvars: (moby: number) -> { [string]: number }?,
}
