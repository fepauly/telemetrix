import Chart from "chart.js/auto"

const ChartjsHook = {
  mounted() {
    this.renderChart();
  },
  updated() {
    this.updateChartData();
  },
  destroyed() {
    if (this.chart) {
      this.chart.destroy();
      this.chart = null;
    }
  },
  renderChart() {
    const rawData = this.el.dataset.chartData;
    let chartData = [];
    try {
      chartData = JSON.parse(rawData);
    } catch (e) {
      chartData = [];
    }

    const labels = chartData.map(d => d.timestamp || d.inserted_at || "-");
    const values = chartData.map(d => d.value);

    this.el.innerHTML = ""; 
    const canvas = document.createElement("canvas");
    this.el.appendChild(canvas);

    this.chart = new Chart(canvas, {
      type: "line",
      data: {
        labels,
        datasets: [{
          label: "Sensor Value",
          data: values,
          fill: false,
        }]
      },
      options: {
        responsive: true,
        plugins: {
          legend: { display: false },
        },
        scales: {
          x: { title: { display: true, text: "Timestamp" }},
          y: { title: { display: true, text: "Value" }}
        }
      }
    });
  },
  updateChartData() {
    const rawData = this.el.dataset.chartData;
    let chartData = [];
    try {
      chartData = JSON.parse(rawData);
    } catch (e) {
      chartData = [];
    }

    const labels = chartData.map(d => d.timestamp || d.inserted_at || "-");
    const values = chartData.map(d => d.value);

    if (this.chart) {
      this.chart.data.labels = labels;
      this.chart.data.datasets[0].data = values;
      this.chart.update();
    } else {
      this.renderChart();
    }
  }
};

export default ChartjsHook;
