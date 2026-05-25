(set! *unchecked-math* true)

(def N 1000)
(def BS 32)

(defn aval [i j]
  (- (* (double (mod (+ (* i 131) (* j 17) 13) 1000)) 0.001) 0.5))

(defn bval [i j]
  (- (* (double (mod (+ (* i 19) (* j 137) 7) 1000)) 0.001) 0.5))

(let [^doubles A (double-array (* N N))
      ^doubles BT (double-array (* N N))
      ^doubles C (double-array (* N N))]
  (dotimes [i N]
    (dotimes [j N]
      (aset-double A (+ (* i N) j) (aval i j))
      (aset-double BT (+ (* j N) i) (bval i j))))

  (let [t0 (System/nanoTime)]
    (doseq [ii (range 0 N BS)]
      (let [iimax (min (+ ii BS) N)]
        (doseq [jj (range 0 N BS)]
          (let [jjmax (min (+ jj BS) N)]
            (loop [i ii]
              (when (< i iimax)
                (let [abase (* i N)]
                  (loop [j jj]
                    (when (< j jjmax)
                      (let [bbase (* j N)
                            s (loop [k 0 acc 0.0]
                                (if (< k N)
                                  (recur (inc k) (+ acc (* (aget A (+ abase k))
                                                           (aget BT (+ bbase k)))))
                                  acc))]
                        (aset-double C (+ abase j) s)
                        (recur (inc j)))))
                  (recur (inc i)))))))))
    (let [t1 (System/nanoTime)
          chk (loop [idx 0 acc 0.0]
                (if (< idx (* N N))
                  (recur (+ idx 97) (+ acc (aget C idx)))
                  acc))]
      (println "language Clojure JVM arrays")
      (printf "time_ms %.6f%n" (/ (- t1 t0) 1000000.0))
      (printf "checksum %.17g%n" chk))))
