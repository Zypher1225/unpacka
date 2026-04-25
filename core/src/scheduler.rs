use rayon::prelude::*;

pub fn run_parallel<T, R, F>(items: Vec<T>, worker: F) -> Vec<R>
where
    T: Send,
    R: Send,
    F: Fn(T) -> R + Sync + Send,
{
    items.into_par_iter().map(worker).collect()
}

