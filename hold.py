import Quartz, time
def post(t, x, y):
    e = Quartz.CGEventCreateMouseEvent(None, t, (x, y), Quartz.kCGMouseButtonLeft)
    Quartz.CGEventPost(Quartz.kCGHIDEventTap, e)
cx = 2426; y0 = 400
post(Quartz.kCGEventMouseMoved, cx, y0); time.sleep(0.1)
post(Quartz.kCGEventLeftMouseDown, cx, y0); time.sleep(0.1)
for i in range(1, 36): post(Quartz.kCGEventLeftMouseDragged, cx, y0 - i*2); time.sleep(0.02)
time.sleep(2.0)   # LONG hold at ~half page
post(Quartz.kCGEventLeftMouseUp, cx, y0 - 70)
print("held and released")
