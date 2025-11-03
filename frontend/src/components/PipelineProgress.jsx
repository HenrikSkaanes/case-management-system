import './PipelineProgress.css';

/**
 * PipelineProgress - Visual pipeline showing ticket flow through stages
 * Shows conversion rates and bottlenecks in the workflow
 */
const PipelineProgress = ({ tickets, stages }) => {
  // Calculate tickets in each stage
  const stageCounts = stages.map(stage => ({
    ...stage,
    count: tickets.filter(t => stage.statuses.includes(t.status)).length
  }));

  const totalTickets = tickets.length || 1;

  // Calculate conversion rate (what % of total tickets are in this stage)
  const stageData = stageCounts.map(stage => ({
    ...stage,
    percentage: (stage.count / totalTickets) * 100,
    width: Math.max((stage.count / totalTickets) * 100, 5) // Minimum 5% for visibility
  }));

  return (
    <div className="pipeline-progress">
      <div className="pipeline-header">
        <h3>📊 Ticket Pipeline</h3>
        <span className="total-count">{totalTickets} total tickets</span>
      </div>
      
      <div className="pipeline-stages">
        {stageData.map((stage, index) => (
          <div key={stage.key} className="pipeline-stage">
            <div className="stage-header">
              <span className="stage-icon">{stage.icon}</span>
              <span className="stage-name">{stage.title}</span>
              <span className="stage-count">{stage.count}</span>
            </div>
            
            <div className="stage-bar-container">
              <div 
                className="stage-bar"
                style={{
                  width: `${stage.width}%`,
                  background: stage.gradient
                }}
              >
                <span className="stage-percentage">{Math.round(stage.percentage)}%</span>
              </div>
            </div>

            {index < stageData.length - 1 && (
              <div className="stage-arrow">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                  <path d="M9 5l7 7-7 7" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              </div>
            )}
          </div>
        ))}
      </div>

      <div className="pipeline-insights">
        {/* Show bottleneck warning if any stage has >40% of tickets */}
        {stageData.some(s => s.percentage > 40) && (
          <div className="insight bottleneck">
            <span className="insight-icon">⚠️</span>
            <span className="insight-text">
              Bottleneck detected in {stageData.find(s => s.percentage > 40).title}
            </span>
          </div>
        )}
        
        {/* Show AI efficiency if AI Processing has tickets */}
        {stageData.find(s => s.key === 'ai_processing')?.count > 0 && (
          <div className="insight ai-active">
            <span className="insight-icon">🤖</span>
            <span className="insight-text">
              AI processing {stageData.find(s => s.key === 'ai_processing').count} drafts
            </span>
          </div>
        )}
      </div>
    </div>
  );
};

export default PipelineProgress;
