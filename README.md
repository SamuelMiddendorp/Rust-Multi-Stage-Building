# Fast Rust (re)deployment with multi stage Docker files

Quick example on how to enable caching in docker for parts of the Rust build process. 
This example uses Rocket as a web framework

## Why?

Because docker has no way to cache different stages of cargo build all dependencies are reinstalled every time a docker image is build.

Run: `docker build -t fast_rust_deployment . -f dockerfile_old` to see our baseline.

Bellow results are running in completely clean docker env, you can use `docker builder prune` to remove all cached docker objects.

-   Baseline first run:
 `[+] Building 179.3s (9/9) FINISHED`

-   Second run takes away the time it took docker to get nightly but all dependencies are still reinstalled:
 `[+] Building 53.1s (9/9) FINISHED`

It is also important to know our image size is well over 4 gb in size:
-   `fast_rust_deployment   latest    2cbd9dab0e9a   5 minutes ago   4.26GB`


 ## Using a multi stage docker file

 If we split up the rust build process we can achieve much faster speeds and much much smaller container sizes. We use the following steps:
 | Step | Responsibility |
 | ---- | ------ |
 | *appetizer* | Prepare the list of dependencies we need for our app   |
 | *starter*   | Install all dependencies defined by our appetizer step |
 |  *main*     | Build our app with all our dependencies already present|

Run: `docker build -t fast_rust_deployment .` to see the improvements:
-   Multi stage first run:
 `[+] Building 185.1s (21/21) FINISHED`
-   Second run we run the exact same command with no changes to the source code:
 `[+] Building 1.1s (21/21) FINISHED`
    - We can take a closer look at what actions docker is actually caching for us (its almost everything):
        ```
     => CACHED [main 2/6] COPY . /app    
     => CACHED [main 3/6] WORKDIR /app
     => CACHED [apetizer 2/5] WORKDIR /app
     => CACHED [apetizer 3/5] RUN cargo install cargo-chef
     => CACHED [apetizer 4/5] COPY . . 
     => CACHED [apetizer 5/5] RUN cargo chef prepare --recipe-path recipe.json
     => CACHED [starter 4/5] COPY --from=apetizer /app/recipe.json recipe.json
     => CACHED [starter 5/5] RUN cargo chef cook --release --recipe-path recipe.json
     => CACHED [main 4/6] COPY --from=starter /app/target target
     => CACHED [main 5/6] COPY --from=starter /usr/local/cargo /usr/local/cargo
     => CACHED [main 6/6] RUN cargo build --release
     => CACHED [stage-3 2/3] COPY --from=main /app/target/release/fast_rust_deployment /app/fast_rust_deployment
     => CACHED [stage-3 3/3] WORKDIR /app     

- The third run we make a small change in the source code of our app:
 `[+] Building 16.6s (21/21) FINISHED`
    - Again its interesting to see what docker has cached for us, it seems we don't have to recompile our dependencies after all!
        ``` 
        => CACHED [apetizer 2/5] WORKDIR /app 
        => CACHED [apetizer 3/5] RUN cargo install cargo-chef
        => CACHED [starter 4/5] COPY --from=apetizer /app/recipe.json recipe.json
        => CACHED [starter 5/5] RUN cargo chef cook --release --recipe-path recipe.json  
        ```

Because all the binaries have been built our final image can be rather small as well:
- `fast_rust_deployment   latest    8d1fb6421aa7   57 minutes ago   75.3MB`

## Concluding

Using multi stage building we can drastically improve our rust build process, with some experimenting the final image can be even smaller. Images of <15mb are not out of the realm of possibility.
Happy dockering!







 

