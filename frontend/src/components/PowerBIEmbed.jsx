import { useState } from 'react';
import './PowerBIEmbed.css';

/**
 * PowerBIEmbed - Component for embedding Power BI reports
 * 
 * Allows embedding Power BI dashboards/reports using iframe
 * Each card can load a different Power BI report
 */
const PowerBIEmbed = ({ title, description, reportUrl, icon }) => {
  const [isExpanded, setIsExpanded] = useState(false);

  return (
    <div className="powerbi-card">
      <div className="powerbi-card-header" onClick={() => setIsExpanded(!isExpanded)}>
        <div className="powerbi-card-title">
          <span className="powerbi-icon">{icon}</span>
          <div>
            <h3>{title}</h3>
            <p className="powerbi-description">{description}</p>
          </div>
        </div>
        <button className="expand-button">
          {isExpanded ? '📊 Collapse' : '📈 View Report'}
        </button>
      </div>

      {isExpanded && (
        <div className="powerbi-embed-container">
          {reportUrl ? (
            <iframe
              title={title}
              src={reportUrl}
              frameBorder="0"
              allowFullScreen
              className="powerbi-iframe"
            ></iframe>
          ) : (
            <div className="powerbi-placeholder">
              <div className="placeholder-icon">📊</div>
              <h4>Power BI Report Not Configured</h4>
              <p>To display a Power BI report here:</p>
              <ol>
                <li>Publish your report to Power BI Service</li>
                <li>Get the embed URL from Power BI</li>
                <li>Add the URL to the configuration below</li>
              </ol>
              <div className="config-example">
                <code>
                  reportUrl="https://app.powerbi.com/view?r=..."
                </code>
              </div>
              <a 
                href="https://docs.microsoft.com/en-us/power-bi/collaborate-share/service-embed-secure" 
                target="_blank" 
                rel="noopener noreferrer"
                className="learn-more-link"
              >
                📖 Learn more about Power BI embedding
              </a>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default PowerBIEmbed;
