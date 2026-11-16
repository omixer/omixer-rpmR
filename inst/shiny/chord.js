// The taxa x modules chord diagram (d3 v6, run by r2d3): taxa and modules as arcs, linked by the module's abundance
// in the taxon. Pointing at an arc fades the links it does not have and shows its name and total in the centre;
// pointing at a link shows its taxon, module and value there.
//
// data (chordData() in R/plots.R): kinds ("taxon" or "module"), labels (on the circle), names (in the centre) and a
// symmetric matrix of the links. options: the colours (chordColours).

svg.selectAll("*").remove();

const outer = Math.max(Math.min(width, height) / 2 - 170, 80);
const inner = outer - 14;
const format = d3.format(",.4~r");

const chords = d3.chord().padAngle(0.02).sortSubgroups(d3.descending)(data.matrix);
const arc = d3.arc().innerRadius(inner).outerRadius(outer);
const ribbon = d3.ribbon().radius(inner - 2);

const chart = svg.append("g")
  .attr("transform", `translate(${width / 2},${height / 2})`)
  .style("font-family", "system-ui, -apple-system, 'Segoe UI', sans-serif");

const links = chart.append("g")
  .selectAll("path")
  .data(chords)
  .join("path")
  .attr("d", ribbon)
  .attr("fill", options.link)
  .attr("fill-opacity", 0.45);

const arcs = chart.append("g")
  .selectAll("g")
  .data(chords.groups)
  .join("g");

arcs.append("path")
  .attr("d", arc)
  .attr("fill", d => data.kinds[d.index] === "taxon" ? options.taxon : options.module)
  .attr("stroke", options.surface)
  .attr("stroke-width", 1);

arcs.append("text")
  .each(d => { d.angle = (d.startAngle + d.endAngle) / 2; })
  .attr("dy", "0.35em")
  .attr("transform", d => `rotate(${d.angle * 180 / Math.PI - 90}) translate(${outer + 6})` +
    (d.angle > Math.PI ? " rotate(180)" : ""))
  .attr("text-anchor", d => d.angle > Math.PI ? "end" : null)
  .attr("font-size", 12)
  .attr("fill", options.text)
  .text(d => data.labels[d.index]);

// the details of what the pointer is on, in the centre of the circle, outlined in the surface colour to stay
// legible over the links
const details = chart.append("text")
  .attr("text-anchor", "middle")
  .attr("font-size", 13)
  .attr("stroke", options.surface)
  .attr("stroke-width", 4)
  .attr("stroke-linejoin", "round")
  .attr("paint-order", "stroke")
  .attr("pointer-events", "none");

// lines: the first one is the name; a hint is shown quietly
function show(lines, hint) {
  details.selectAll("tspan")
    .data(lines)
    .join("tspan")
    .attr("x", 0)
    .attr("dy", (line, i) => i === 0 ? `${-0.6 * (lines.length - 1)}em` : "1.2em")
    .attr("fill", (line, i) => i === 0 && !hint ? options.title : options.text)
    .attr("font-weight", (line, i) => i === 0 && !hint ? 600 : 400)
    .text(line => line);
}

function reset() {
  links.attr("fill", options.link).attr("fill-opacity", 0.45);
  show(["Point at a taxon, a module or a link"], true);
}

arcs.on("mouseover", (event, d) => {
  const own = link => link.source.index === d.index || link.target.index === d.index;
  links
    .attr("fill", link => own(link) ? options.link : options.faded)
    .attr("fill-opacity", link => own(link) ? 0.85 : 0.5);
  show([data.names[d.index], `${format(d.value)} in total`]);
}).on("mouseout", reset);

links.on("mouseover", (event, d) => {
  links.attr("fill", link => link === d ? options.link : options.faded)
    .attr("fill-opacity", link => link === d ? 0.85 : 0.5);
  show([data.names[d.source.index], data.names[d.target.index], format(d.source.value)]);
}).on("mouseout", reset);

reset();
