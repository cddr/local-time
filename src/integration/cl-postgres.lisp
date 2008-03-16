(in-package :local-time)

(export 'set-local-time-cl-postgres-readers :local-time)

;; Postgresql days are measured from 01-01-2000, whereas local-time
;; uses 01-03-2000. We expect the database server to be in the UTC timezone.
(defconstant +postgres-day-offset-to-local-time+ -60)

(defun set-local-time-cl-postgres-readers (&optional (table cl-postgres:*sql-readtable*))
  (cl-postgres:set-sql-datetime-readers
   :table table
   :date
   (lambda (days)
     (local-time:make-local-time
      :nsec 0 :sec 0 :day (+ days +postgres-day-offset-to-local-time+)
      :timezone local-time:+utc-zone+))
   :timestamp
   (lambda (usecs)
     (multiple-value-bind (days usecs)
         (floor usecs +usecs-per-day+)
       (multiple-value-bind (secs usecs)
           (floor usecs 1000000)
         (local-time:make-local-time :nsec (* usecs 1000)
                                     :sec secs
                                     :day (+ days +postgres-day-offset-to-local-time+)
                                     :timezone local-time:+utc-zone+))))
   :interval
   (lambda (months days usecs)
     (declare (ignore months days usecs))
     (error "Intervals are not yet supported"))
   :time
   (lambda (usecs)
     (multiple-value-bind (days usecs)
         (floor usecs +usecs-per-day+)
       (assert (= days 0))
       (multiple-value-bind (secs usecs)
           (floor usecs 1000000)
         (local-time:make-local-time
          :nsec (* usecs 1000)
          :sec secs
          :day 0
          :timezone local-time:+utc-zone+))))))

(defmethod cl-postgres:to-sql-string ((arg local-time:local-time))
  (local-time:format-rfc3339-timestring arg))