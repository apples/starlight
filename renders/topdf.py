from fpdf import FPDF
import itertools
import argparse

parser = argparse.ArgumentParser(description='Render the cards to a PDF.')
parser.add_argument('cardlist', type=str, help='A file containing a list of the card file names. Card file names will automatically have "images/" prepended to them.')
parser.add_argument('--singles', action='store_true', help='Render single copies instead of full playsets.')

args = parser.parse_args()

cards = []

with open(args.cardlist) as file:
    cards = ["images/"+line.rstrip() for line in file]

if len(cards) == 0:
    exit(-1)

pdf = FPDF('P', 'in', (2.5*3,3.5*3))

page_full = True
x = 0
y = 0

def render_card(filename):
    global page_full
    global x
    global y
    if page_full:
        pdf.add_page()
        page_full = False
        x = 0
        y = 0
    pdf.image(filename, w=2.5, h=3.5, x=x*2.5, y=y*3.5)
    x = x + 1
    if x == 3:
        x = 0
        y = y + 1
    if y == 3:
        page_full = True

N = 3
if args.singles:
    N = 1

for card in cards:
    for i in range(N):
        render_card(card)

pdf.output("cards.pdf")

