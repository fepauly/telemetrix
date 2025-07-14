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
    
    // Determine if we're in dark mode for better color choices
    const isDarkMode = document.documentElement.getAttribute('data-theme') === 'dark';
    const gridColor = isDarkMode ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)';
    const textColor = isDarkMode ? 'rgba(255, 255, 255, 0.7)' : 'rgba(0, 0, 0, 0.7)';

    this.chart = new Chart(canvas, {
      type: "line",
      data: {
        labels,
        datasets: [{
          label: "Sensor Value",
          data: values,
          fill: true,
          backgroundColor: isDarkMode ? 'rgba(147, 51, 234, 0.1)' : 'rgba(168, 85, 247, 0.1)',
          borderColor: isDarkMode ? 'rgba(147, 51, 234, 0.7)' : 'rgba(168, 85, 247, 0.7)',
          borderWidth: 2,
          pointRadius: 3,
          pointHoverRadius: 5,
          pointBackgroundColor: isDarkMode ? 'rgba(147, 51, 234, 1)' : 'rgba(168, 85, 247, 1)',
          tension: 0.3,
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: {
          duration: 500,
        },
        interaction: {
          mode: 'index',
          intersect: false,
        },
        plugins: {
          legend: { display: false },
          tooltip: {
            backgroundColor: isDarkMode ? 'rgba(30, 30, 30, 0.9)' : 'rgba(255, 255, 255, 0.9)',
            titleColor: isDarkMode ? 'rgba(255, 255, 255, 0.9)' : 'rgba(0, 0, 0, 0.9)',
            bodyColor: isDarkMode ? 'rgba(255, 255, 255, 0.7)' : 'rgba(0, 0, 0, 0.7)',
            borderColor: isDarkMode ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)',
            borderWidth: 1,
            cornerRadius: 8,
            padding: 10,
            displayColors: false,
            callbacks: {
              label: function(context) {
                return `Value: ${context.raw}`;
              }
            }
          }
        },
        scales: {
          x: { 
            grid: {
              color: gridColor,
              drawBorder: false,
            },
            ticks: {
              color: textColor,
              maxRotation: 0,
              autoSkip: true,
              maxTicksLimit: 8,
            },
            title: { 
              display: true, 
              text: "Timestamp",
              color: textColor,
              padding: {top: 10, bottom: 0},
            }
          },
          y: { 
            grid: {
              color: gridColor,
              drawBorder: false,
            },
            ticks: {
              color: textColor,
            },
            title: { 
              display: true, 
              text: "Value",
              color: textColor,
              padding: {top: 0, bottom: 10},
            },
            beginAtZero: true,
          }
        }
      }
    });
    
    // Listen for theme changes and update chart
    window.addEventListener("phx:set-theme", () => {
      this.chart.destroy();
      this.renderChart();
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
      this.chart.update('active');
    } else {
      this.renderChart();
    }
  }
};

export default ChartjsHook;
