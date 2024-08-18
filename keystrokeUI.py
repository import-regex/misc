import tkinter as tk
from pynput import keyboard

# Initialize variables
recent_keys = []
active_keys = set()

# Function to handle key presses
def on_press(key):
    try:
        key_char = key.char
    except AttributeError:
        key_char = str(key)

    # Update recent keys list
    if len(recent_keys) >= 5:
        recent_keys.pop(0)
    recent_keys.append(key_char)

    # Add to active keys
    active_keys.add(key_char)

    # Update the label with recent keys
    update_label()

# Function to handle key releases
def on_release(key):
    try:
        key_char = key.char
    except AttributeError:
        key_char = str(key)
    
    # Remove from active keys
    if key_char in active_keys:
        active_keys.remove(key_char)

    # Update the label with recent keys
    update_label()

# Function to update the label with recent keys and highlight active keys
def update_label():
    display_text = '\n'.join(recent_keys)
    for key in active_keys:
        display_text = display_text.replace(key, f"[{key}]")
    key_label.config(text=display_text)

# Function to close the application
def close_app():
    root.quit()
    listener.stop()

# Create the main tkinter window
root = tk.Tk()
root.geometry("350x250+50+130")
root.overrideredirect(True)
root.attributes("-topmost", True)
root.attributes("-transparentcolor", root['bg'])

# Make the window draggable
def start_move(event):
    root.x = event.x
    root.y = event.y

def stop_move(event):
    root.x = None
    root.y = None

def do_move(event):
    x = root.winfo_pointerx() - root.x
    y = root.winfo_pointery() - root.y
    root.geometry(f"+{x}+{y}")

root.bind("<ButtonPress-1>", start_move)
root.bind("<ButtonRelease-1>", stop_move)
root.bind("<B1-Motion>", do_move)

# Add a label to show the recent keys
key_label = tk.Label(root, text="", font=("Helvetica", 20), fg="white", bg="black")
key_label.pack(expand=True)

# Add a transparent close button
close_button = tk.Button(root, text="X", command=close_app, fg="white", bg="black", bd=0, highlightthickness=0)

def on_enter(event):
    close_button.config(bg="red")

def on_leave(event):
    close_button.config(bg="black")

close_button.bind("<Enter>", on_enter)
close_button.bind("<Leave>", on_leave)
close_button.place(x=320, y=10)

# Start the key listener
with keyboard.Listener(on_press=on_press, on_release=on_release) as listener:
    root.mainloop()
