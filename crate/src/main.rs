#![cfg_attr(flux, feature(step_trait, allocator_api))]
#![allow(dead_code)]
#![allow(unused)]

flux_rs::defs! {
    qualifier MyQ1(x: int, y: int, z: int) { x == y + z }
    qualifier MyQ2(x: int, y: int, z: int) { x == y - z }
}

extern crate flux_alloc;
extern crate flux_core;

pub mod ch01_refinements;
pub mod ch02_ownership;
pub mod ch03_structs;
pub mod ch04_enums;

fn main() {
    return;
}
