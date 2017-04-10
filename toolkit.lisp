#|
 This file is a part of cl-soloud
 (c) 2017 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.fraf.soloud)

(defvar *c-object-table* (tg:make-weak-hash-table :test 'eql :weakness :value))

(defclass c-backed-object ()
  ((handle :initform NIL :accessor handle)))

(defmethod initialize-instance :after ((c-backed-object c-backed-object) &key)
  (let ((handle (create-handle c-backed-object)))
    (when (cffi:null-pointer-p handle)
      (error "Failed to create ~a handle." c-backed-object))
    (setf (handle soloud) handle)
    (tg:finalize handle (destroy-handle c-backed-object handle))))

(defclass c-tracked-object (c-backed-object)
  ())

(defmethod initialize-instance :around ((object c-tracked-object) &key)
  (call-next-method)
  (setf (gethash (cffi:pointer-address (handle object)) *c-object-table*) object))

(defmethod pointer->object ((pointer integer))
  (gethash integer *c-object-table*))

(defmethod pointer->object (pointer)
  (gethash (cffi:pointer-address pointer) *c-object-table*))

(defmacro with-callback-handling ((instance &optional default) &body body)
  `(handler-case
       (let ((,instance (pointer->object ,instance)))
         (if ,instance
             ,@body
             ,default))
     (error (err)
       (format T "~&! Error in callback: ~a~%" err)
       ,default)))
