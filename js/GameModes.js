const GameModes = {
    classic: {
        numCols: 1,
        numRows: 10,
        theme: 'classic',
        hasSkills: true,
        hasTimer: false,
        enableHorizontalMatches: false,
        blockWidthPercent: 0.65,
        title: '三消挑戰',
        description: '經典單排模式'
    },
    
    double: {
        numCols: 2,
        numRows: 10,
        theme: 'double',
        hasSkills: true,
        hasTimer: false,
        enableHorizontalMatches: false,
        title: '雙排挑戰',
        description: '快速雙排模式'
    },
    
    triple: {
        numCols: 3,
        numRows: 10,
        theme: 'triple',
        hasSkills: true,
        hasTimer: false,
        enableHorizontalMatches: true,
        title: '三排挑戰',
        description: '進階三排模式'
    },
    
    timeLimit: {
        numCols: 3,
        numRows: 10,
        theme: 'time',
        hasSkills: false,
        hasTimer: true,
        gameDuration: 45000,
        enableHorizontalMatches: true,
        title: '45秒限時挑戰',
        description: '限時挑戰模式'
    }
};

// 導出模式配置
if (typeof module !== 'undefined' && module.exports) {
    module.exports = GameModes;
} 