// SPDX-FileCopyrightText: Copyright (c) 2017-2023 slowtec GmbH <post@slowtec.de>
// SPDX-License-Identifier: MIT OR Apache-2.0

//! # TCP server example
//!
//! This example shows how to start a server and implement basic register
//! read/write operations.

use std::{
    collections::HashMap,
    net::SocketAddr,
    sync::{Arc, Mutex},
};

use futures::future;
use tokio::net::TcpListener;

use tokio_modbus::{
    prelude::*,
    server::tcp::{accept_tcp_connection, Server},
};

struct ModbusSimulator {
    input_registers: Arc<Mutex<HashMap<u16, u16>>>,
    holding_registers: Arc<Mutex<HashMap<u16, u16>>>,
}

impl tokio_modbus::server::Service for ModbusSimulator {
    type Request = Request<'static>;
    type Response = Response;
    type Error = std::io::Error;
    type Future = future::Ready<Result<Self::Response, Self::Error>>;

    fn call(&self, req: Self::Request) -> Self::Future {
        match req {
            Request::ReadInputRegisters(addr, cnt) => {
                match register_read(&self.input_registers.lock().unwrap(), addr, cnt) {
                    Ok(values) => future::ready(Ok(Response::ReadInputRegisters(values))),
                    Err(err) => future::ready(Err(err)),
                }
            }
            Request::ReadHoldingRegisters(addr, cnt) => {
                match register_read(&self.holding_registers.lock().unwrap(), addr, cnt) {
                    Ok(values) => future::ready(Ok(Response::ReadHoldingRegisters(values))),
                    Err(err) => future::ready(Err(err)),
                }
            }
            Request::WriteMultipleRegisters(addr, values) => {
                match register_write(&mut self.holding_registers.lock().unwrap(), addr, &values) {
                    Ok(_) => future::ready(Ok(Response::WriteMultipleRegisters(
                        addr,
                        values.len() as u16,
                    ))),
                    Err(err) => future::ready(Err(err)),
                }
            }
            Request::WriteSingleRegister(addr, value) => {
                match register_write(
                    &mut self.holding_registers.lock().unwrap(),
                    addr,
                    std::slice::from_ref(&value),
                ) {
                    Ok(_) => future::ready(Ok(Response::WriteSingleRegister(addr, value))),
                    Err(err) => future::ready(Err(err)),
                }
            }
            _ => {
                println!("SERVER: Exception::IllegalFunction - Unimplemented function code in request: {req:?}");
                // TODO: We want to return a Modbus Exception response `IllegalFunction`. https://github.com/slowtec/tokio-modbus/issues/165
                future::ready(Err(std::io::Error::new(
                    std::io::ErrorKind::AddrNotAvailable,
                    "Unimplemented function code in request".to_string(),
                )))
            }
        }
    }
}

impl ModbusSimulator {
    fn new() -> Self {
        // Insert some test data as register values.
        let mut input_registers = HashMap::new();
        input_registers.insert(0, 1234);
        input_registers.insert(1, 5678);
        let mut holding_registers = HashMap::new();
        holding_registers.insert(0, 10);
        holding_registers.insert(1, 20);
        holding_registers.insert(2, 30);
        holding_registers.insert(3, 40);
        Self {
            input_registers: Arc::new(Mutex::new(input_registers)),
            holding_registers: Arc::new(Mutex::new(holding_registers)),
        }
    }
}

/// Helper function implementing reading registers from a HashMap.
fn register_read(
    registers: &HashMap<u16, u16>,
    addr: u16,
    cnt: u16,
) -> Result<Vec<u16>, std::io::Error> {
    let mut response_values = vec![0; cnt.into()];
    for i in 0..cnt {
        let reg_addr = addr + i;
        if let Some(r) = registers.get(&reg_addr) {
            response_values[i as usize] = *r;
        } else {
            // TODO: Return a Modbus Exception response `IllegalDataAddress` https://github.com/slowtec/tokio-modbus/issues/165
            println!("SERVER: Exception::IllegalDataAddress");
            return Err(std::io::Error::new(
                std::io::ErrorKind::AddrNotAvailable,
                format!("no register at address {reg_addr}"),
            ));
        }
    }

    Ok(response_values)
}

/// Write a holding register. Used by both the write single register
/// and write multiple registers requests.
fn register_write(
    registers: &mut HashMap<u16, u16>,
    addr: u16,
    values: &[u16],
) -> Result<(), std::io::Error> {
    for (i, value) in values.iter().enumerate() {
        let reg_addr = addr + i as u16;
        if let Some(r) = registers.get_mut(&reg_addr) {
            *r = *value;
        } else {
            // TODO: Return a Modbus Exception response `IllegalDataAddress` https://github.com/slowtec/tokio-modbus/issues/165
            println!("SERVER: Exception::IllegalDataAddress");
            return Err(std::io::Error::new(
                std::io::ErrorKind::AddrNotAvailable,
                format!("no register at address {reg_addr}"),
            ));
        }
    }

    Ok(())
}

#[tokio::main(flavor = "current_thread")]
pub async fn server_context(
    socket_addr: String,
    notify: std::sync::Arc<tokio::sync::Notify>,
) -> anyhow::Result<()> {
    let socket_addr = socket_addr.parse::<SocketAddr>().unwrap();
    println!("SERVER: Starting server on {socket_addr}");
    let listener = TcpListener::bind(socket_addr).await?;
    let server = Server::new(listener);
    let new_service = |_socket_addr| Ok(Some(ModbusSimulator::new()));
    let on_connected = |stream, socket_addr| async move {
        accept_tcp_connection(stream, socket_addr, new_service)
    };
    let on_process_error = |err| {
        eprintln!("{err}");
    };

    let abort_signal = Box::pin(async move {
        notify.notified().await;
        println!("Stopping server...");
    });

    server
        .serve_until(&on_connected, on_process_error, abort_signal)
        .await?;
    Ok(())
}
