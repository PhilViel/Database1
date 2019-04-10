/****************************************************************************************************
  Description : Détermine si un représentant est recrut à une date donnée selon 
                sa date de début d'affaire.             
   
  Variables : 
   @FBusinessStart : Date de début d'affaire du représentant
   @FDayToEvaluate : La fonction détermine si le représentant est recrue ou non à cette date                                                                          

  Resultat    : True  = C'est une recrue
                False = Ce n'est pas une recrue

 ******************************************************************************
  27-04-2003 André           Création
  15-06-2003 BrunoL          Documentation
 ******************************************************************************/
CREATE FUNCTION dbo.fn_Un_IsRecruit
(
  @FBusinessStart MoDate,
  @FDayToEvaluate MoDate 
)
RETURNS MoBitFalse            -- True = c'est une recrue  False = ce n'est pas une recrue
AS
BEGIN
  DECLARE
    @EffectDate  MoDate,      -- Date effective de l'enregistrement de configuration  
    @FMonths     MoID,        -- Variable qui contiendra le nombre de mois ou le représentant est recrue à partir de ca
                              -- date de début d'affaire.  Selon ca date d'affaire. 
    @IsRecruit   MoBitFalse   -- C'est la variable qui contient la réponse à la question. Est-ce une recru à cette date.

  SET @EffectDate = NULL
/* Fonctionnement de la table Un_RepRecruitMonthCfg :
   
   La table Un_RepRecruitMonthCfg contient la configuration de la durée d'un représentant comme recru à partir de ca date d'affaire.  Pour savoir 
   la durée en temps, il faut aller chercher l'enregistrement dont la date effective est la plus grande parmis les enregistrements dont la date effective 
   est plus petite ou égal à la date de début d'affaire du représentant.  Cette enregistrement contient le nombre de mois ou le représentant est recru à 
   partir de ca date de début d'affaire.  Par exemple un représentant qui à commencer le 01-01-2000 et dont le nombre de mois de la table est 8 sera 
   recrue du 01-01-2000 au 31-08-2000.
*/
  SELECT @EffectDate = MAX(EffectDate)  
  FROM Un_RepRecruitMonthCfg
  WHERE (EffectDate <= @FBusinessStart)


  IF @EffectDate IS NULL
    RETURN(0);

  SELECT @FMonths = Months             
  FROM Un_RepRecruitMonthCfg
  WHERE (EffectDate = @EffectDate)

  IF DATEADD(mm,@FMonths,@FBusinessStart) > @FDayToEvaluate 
    SET @IsRecruit = 1
  ELSE
    SET @IsRecruit = 0

  RETURN(@IsRecruit)
END

