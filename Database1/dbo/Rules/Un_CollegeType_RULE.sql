CREATE RULE [dbo].[Un_CollegeType_RULE]
    AS @CollegeType IN ('01','02','03','04');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_CollegeType_RULE]', @objname = N'[dbo].[Un_College].[CollegeTypeID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_CollegeType_RULE]', @objname = N'[dbo].[Un_CESP400].[cCollegeTypeID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_CollegeType_RULE]', @objname = N'[dbo].[UnCollegeType]';

