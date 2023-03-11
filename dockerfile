FROM rustlang/rust:nightly as apetizer
WORKDIR /app
RUN cargo install cargo-chef
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM rustlang/rust:nightly as starter
WORKDIR /app
RUN cargo install cargo-chef
COPY --from=apetizer /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json

FROM rustlang/rust:nightly as main
COPY . /app
WORKDIR /app
COPY --from=starter /app/target target
COPY --from=starter /usr/local/cargo /usr/local/cargo
RUN cargo build --release

FROM debian:buster-slim
COPY --from=main /app/target/release/fast_rust_deployment /app/fast_rust_deployment
WORKDIR /app
CMD ["./fast_rust_deployment"]